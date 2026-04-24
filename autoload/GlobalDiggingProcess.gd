extends Node

signal block_hp_updated(lane_index: int, block_uid: String, hp: float, max_hp: float, hp_percent: float)
signal block_destroyed(lane_index: int, block_uid: String)
signal boss_special_blocked_hit(lane_index: int, block_uid: String, reason: String)

const BASE_HIT_INTERVAL := 1.0

# runtime only, do not save
# lane_index -> {
#   bot_uid,
#   bot_level,
#   dig_power,
#   dig_speed,
#   current_block_uid,
#   hit_progress
# }
var _lane_runtime: Dictionary = {}
var _is_syncing := false


func _ready() -> void:
	GlobalSignals.DataSaved.connect(SyncDiggingLanes)
	set_process(true)


func _process(delta: float) -> void:
	if _lane_runtime.is_empty():
		SyncDiggingLanes()

	_ProcessBossPassiveLanes(delta)

	for lane_index in _lane_runtime.keys().duplicate():
		_ProcessLane(int(lane_index), delta)


func _ProcessBossPassiveLanes(delta: float) -> void:
	for lane_index in range(GlobalSave.save_data.lanes.size()):
		var lane = GlobalSave.save_data.lanes[lane_index]

		if !lane.auto_dig_unlocked:
			continue

		if lane.block_data.is_empty():
			continue

		var front_block = lane.block_data[0]
		if !bool(front_block.get("is_boss", false)):
			continue

		_ProcessBossSpecial(lane_index, delta)
		
func SyncDiggingLanes() -> void:
	if _is_syncing:
		return
	_is_syncing = true

	var active_lane_list: Array = _FindLanesToStartDig()
	var active_lookup := {}

	for lane_index in active_lane_list:
		lane_index = int(lane_index)
		active_lookup[lane_index] = true
		_SyncLaneRuntime(lane_index)

	# stop lanes that are no longer active
	for lane_index in _lane_runtime.keys().duplicate():
		lane_index = int(lane_index)
		if !active_lookup.has(lane_index):
			_lane_runtime.erase(lane_index)

	_is_syncing = false


func _EmitBlockHpUpdated(lane_index: int) -> void:
	if lane_index < 0 or lane_index >= GlobalSave.save_data.lanes.size():
		return

	var lane = GlobalSave.save_data.lanes[lane_index]

	if !lane.has("block_data") or lane.block_data.is_empty():
		return

	var block: Dictionary = lane.block_data[0]

	var hp_big: Dictionary = GlobalBigNumber.ToBig(block.get("hp", 0.0))
	var max_hp_big: Dictionary = GlobalBigNumber.ToBig(block.get("max_hp", 1.0))
	var hp_percent := GlobalBigNumber.Percent(hp_big, max_hp_big)

	block_hp_updated.emit(
		lane_index,
		str(block.get("uid", "")),
		hp_big,
		max_hp_big,
		hp_percent
	)
	
func _FindLanesToStartDig() -> Array:
	var lane_index_list: Array = []

	for i in range(GlobalSave.save_data.lanes.size()):
		var lane = GlobalSave.save_data.lanes[i]
		if lane.auto_dig_unlocked and int(lane.bot_uid) != -1 and lane.block_data.size() > 0:
			lane_index_list.append(i)

	return lane_index_list


func _SyncLaneRuntime(lane_index: int) -> void:
	if lane_index < 0 or lane_index >= GlobalSave.save_data.lanes.size():
		return

	var lane = GlobalSave.save_data.lanes[lane_index]

	if lane.block_data.is_empty():
		_lane_runtime.erase(lane_index)
		return

	var bot: Dictionary = _FindBotByUid(int(lane.bot_uid))
	if bot.is_empty():
		_lane_runtime.erase(lane_index)
		return

	var current_block = lane.block_data[0]

	var new_runtime := {
		"bot_uid": int(lane.bot_uid),
		"bot_level": int(bot.get("level", 1)),
		"dig_power": _GetBotDigPower(bot),
		"dig_speed": _GetBotDigSpeed(bot),
		"current_block_uid": str(current_block.uid),
		"hit_progress": 0.0
	}

	# cache lane stats for UI / save access
	lane.dig_power = new_runtime["dig_power"]
	lane.dig_speed = new_runtime["dig_speed"]

	# first time this lane becomes active
	if !_lane_runtime.has(lane_index):
		_lane_runtime[lane_index] = new_runtime
		return

	var old_runtime: Dictionary = _lane_runtime[lane_index]

	var bot_changed = old_runtime["bot_uid"] != new_runtime["bot_uid"]
	var level_changed = old_runtime["bot_level"] != new_runtime["bot_level"]
	var block_changed = str(old_runtime["current_block_uid"]) != str(new_runtime["current_block_uid"])
	var stats_changed := (
		!is_equal_approx(float(old_runtime["dig_power"]), float(new_runtime["dig_power"])) or
		!is_equal_approx(float(old_runtime["dig_speed"]), float(new_runtime["dig_speed"]))
	)

	# if same lane bot got upgraded or replaced -> reset current block progress
	if bot_changed or level_changed or stats_changed:
		_ResetCurrentBlockProgress(lane_index)
		new_runtime["hit_progress"] = 0.0
	elif block_changed:
		new_runtime["hit_progress"] = 0.0
	else:
		# keep current timing progress for unchanged lanes
		new_runtime["hit_progress"] = float(old_runtime.get("hit_progress", 0.0))

	_lane_runtime[lane_index] = new_runtime

func _ProcessLane(lane_index: int, delta: float) -> void:
	if lane_index < 0 or lane_index >= GlobalSave.save_data.lanes.size():
		_lane_runtime.erase(lane_index)
		return

	var lane = GlobalSave.save_data.lanes[lane_index]

	if !lane.auto_dig_unlocked or int(lane.bot_uid) == -1:
		_lane_runtime.erase(lane_index)
		return

	if lane.block_data.is_empty():
		GenerateNextBlocksForLane(lane_index)
		if lane.block_data.is_empty():
			_lane_runtime.erase(lane_index)
			return

	if !_lane_runtime.has(lane_index):
		_SyncLaneRuntime(lane_index)
		if !_lane_runtime.has(lane_index):
			return

	var runtime: Dictionary = _lane_runtime[lane_index]

	# block changed externally
	if str(runtime.get("current_block_uid", "")) != str(lane.block_data[0].uid):
		runtime["current_block_uid"] = str(lane.block_data[0].uid)
		runtime["hit_progress"] = 0.0

	# boss passive specials tick here
	if bool(lane.block_data[0].get("is_boss", false)):
		_ProcessBossSpecial(lane_index, delta)

	runtime["hit_progress"] += delta

	var hit_interval := _GetHitInterval(float(runtime.get("dig_speed", 1.0)))
	while float(runtime["hit_progress"]) >= hit_interval:
		runtime["hit_progress"] -= hit_interval

		var did_destroy := _ApplyDamageToFrontBlock(
			lane_index,
			float(runtime.get("dig_power", 1.0)),
			false
		)

		if did_destroy:
			if !_lane_runtime.has(lane_index):
				return
			if lane_index >= GlobalSave.save_data.lanes.size():
				return
			lane = GlobalSave.save_data.lanes[lane_index]
			if lane.block_data.is_empty():
				return

			runtime = _lane_runtime[lane_index]
			runtime["current_block_uid"] = str(lane.block_data[0].uid)
			
func _FinishFrontBlock(lane_index: int, destroy_context: Dictionary = {}) -> void:
	var lane = GlobalSave.save_data.lanes[lane_index]

	if lane.block_data.is_empty():
		return

	var finished_block: Dictionary = lane.block_data[0]
	var finished_depth := int(finished_block.get("depth", int(lane.lane_depth)))

	lane.last_cleared_depth = max(
		int(lane.get("last_cleared_depth", -1)),
		finished_depth
	)

	if bool(finished_block.get("is_boss", false)):
		_HandleBossBlockFinished(finished_block)
	else:
		var reward_mult = max(1.0, float(destroy_context.get("reward_mult", 1.0)))
		_GrantRolledBlockDrops(finished_block, reward_mult)

	lane.lane_depth = int(lane.lane_depth) + 1
	GlobalSave.SetGlobalDepth(lane.lane_depth)
	lane.block_data.remove_at(0)

	if lane.block_data.is_empty():
		GenerateNextBlocksForLane(lane_index)

	RefreshLaneDigging(lane_index)
	GlobalSave.SyncSave()

func _ResetCurrentBlockProgress(lane_index: int) -> void:
	var lane = GlobalSave.save_data.lanes[lane_index]
	if lane.block_data.is_empty():
		return

	# reset same front block back to full hp
	lane.block_data[0].hp = GlobalBigNumber.ToBig(lane.block_data[0].max_hp).duplicate(true)

	if _lane_runtime.has(lane_index):
		_lane_runtime[lane_index]["hit_progress"] = 0.0
		_lane_runtime[lane_index]["current_block_uid"] = str(lane.block_data[0].uid)
	_EmitBlockHpUpdated(lane_index)

func _FindBotByUid(bot_uid: int) -> Dictionary:
	for bot in GlobalSave.save_data.bot_inventory.bot_db:
		if int(bot.uid) == bot_uid:
			return bot
	return {}


func _GetBotDigSpeed(bot: Dictionary) -> float:
	var level := int(bot.get("level", 1))

	var speed := float(GlobalStats.GetBotBaseDigSpeed(level))
	speed += GlobalBotStats.GetBotStatValue(bot, "dig_speed")

	speed *= GlobalStats.GetGlobalSpeedMultiplier()
	speed *= GlobalBotStats.BotStatMultiplier(bot, "dig_speed_mult")
	speed *= GlobalStats.GetUpgradeValue("drill_speed")

	return max(0.001, speed)


func _GetBotDigPower(bot: Dictionary) -> float:
	var dps := float(GlobalStats.GetBotFinalDPSWithGlobalAndStats(bot, false, false,true))
	var speed := _GetBotDigSpeed(bot)

	return max(0.0, dps / max(speed, 0.001))


func _GetHitInterval(dig_speed: float) -> float:
	return BASE_HIT_INTERVAL / max(dig_speed, 0.001)

	
func GetLaneCurrentBlock(lane_index: int) -> Dictionary:
	if lane_index < 0 or lane_index >= GlobalSave.save_data.lanes.size():
		return {}

	var lane = GlobalSave.save_data.lanes[lane_index]
	if lane.block_data.is_empty():
		return {}

	return lane.block_data[0]


func GetLaneCurrentHp(lane_index: int) -> float:
	var block = GetLaneCurrentBlock(lane_index)
	if block.is_empty():
		return 0.0
	return GlobalBigNumber.ToFloatSafe(block.get("hp", 0.0))

func GetLaneCurrentMaxHp(lane_index: int) -> float:
	var block = GetLaneCurrentBlock(lane_index)
	if block.is_empty():
		return 0.0
	return GlobalBigNumber.ToFloatSafe(block.get("max_hp", 0.0))

func GetLaneCurrentHpLeftPercent(lane_index: int) -> float:
	var block = GetLaneCurrentBlock(lane_index)
	if block.is_empty():
		return 0.0

	return GlobalBigNumber.Percent(
		block.get("hp", 0.0),
		block.get("max_hp", 1.0)
	)


func GetLaneCurrentBlockName(lane_index: int) -> String:
	var block = GetLaneCurrentBlock(lane_index)
	if block.is_empty():
		return ""
	return str(block.name)


func GetLaneCurrentBlockId(lane_index: int) -> String:
	var block = GetLaneCurrentBlock(lane_index)
	if block.is_empty():
		return ""
	return str(block.id)


func GetLaneCurrentBlockUid(lane_index: int) -> String:
	var block = GetLaneCurrentBlock(lane_index)
	if block.is_empty():
		return ""
	return str(block.uid)


func IsLaneDigging(lane_index: int) -> bool:
	if lane_index < 0 or lane_index >= GlobalSave.save_data.lanes.size():
		return false

	var lane = GlobalSave.save_data.lanes[lane_index]
	return lane.auto_dig_unlocked and int(lane.bot_uid) != -1 and lane.block_data.size() > 0


func GetLaneDigInfo(lane_index: int) -> Dictionary:
	if !IsLaneDigging(lane_index):
		return {
			"is_digging": false,
			"block_name": "",
			"block_id": "",
			"block_uid": "",
			"hp": 0.0,
			"max_hp": 0.0,
			"hp_percent": 0.0
		}

	var block = GetLaneCurrentBlock(lane_index)

	return {
		"is_digging": true,
		"block_name": str(block.name),
		"block_id": str(block.id),
		"block_uid": str(block.uid),
		"hp": GlobalBigNumber.ToFloatSafe(block.get("hp", 0.0)),
		"max_hp": GlobalBigNumber.ToFloatSafe(block.get("max_hp", 0.0)),
		"hp_percent": GlobalBigNumber.Percent(block.get("hp", 0.0), block.get("max_hp", 1.0)),
		"hp_text": GlobalBigNumber.Format(block.get("hp", 0.0)),
		"max_hp_text": GlobalBigNumber.Format(block.get("max_hp", 0.0))
	}

func RefreshLaneDigging(lane_index: int) -> void:
	if lane_index < 0 or lane_index >= GlobalSave.save_data.lanes.size():
		return

	_lane_runtime.erase(lane_index)

	var lane = GlobalSave.save_data.lanes[lane_index]

	if !lane.auto_dig_unlocked:
		return
	if int(lane.bot_uid) == -1:
		return

	if lane.block_data.is_empty():
		GenerateNextBlocksForLane(lane_index)

	if lane.block_data.is_empty():
		return

	_SyncLaneRuntime(lane_index)
	
	_EmitBlockHpUpdated(lane_index)

func CreateGeneratedBlockForDepth(lane_index: int, block_depth: int) -> Dictionary:
	var normal_block = GlobalBlockDatabase.CreateBlockForLane(block_depth, lane_index)
	if normal_block.is_empty():
		return {}

	normal_block = _ConvertGeneratedBlockHpToBigNumber(normal_block)

	var normal_hp := GlobalBigNumber.ToBig(normal_block.get("max_hp", normal_block.get("hp", 1.0)))
	var normal_reward := int(normal_block.get("reward_amount", 0))

	var boss_block = GlobalBossDb.TryGenerateBossBlock(
		block_depth,
		lane_index,
		normal_hp,
		normal_reward
	)

	if !boss_block.is_empty():
		if !boss_block.has("id"):
			boss_block["id"] = str(boss_block.get("boss_id", "boss"))
		if !boss_block.has("reward_type"):
			boss_block["reward_type"] = "coins"
		if !boss_block.has("reward_amount"):
			boss_block["reward_amount"] = int(boss_block.get("reward_coins", 0))

		boss_block = _ConvertGeneratedBlockHpToBigNumber(boss_block)
		return boss_block

	return normal_block


func _ConvertGeneratedBlockHpToBigNumber(block: Dictionary) -> Dictionary:
	if block.has("hp"):
		block["hp"] = GlobalBigNumber.ToBig(block["hp"])

	if block.has("max_hp"):
		block["max_hp"] = GlobalBigNumber.ToBig(block["max_hp"])

	if block.has("base_hp"):
		block["base_hp"] = GlobalBigNumber.ToBig(block["base_hp"])

	if !block.has("hp") and block.has("max_hp"):
		block["hp"] = GlobalBigNumber.ToBig(block["max_hp"])

	if block.has("hp") and block.has("max_hp"):
		if GlobalBigNumber.Compare(block["hp"], block["max_hp"]) > 0:
			block["hp"] = GlobalBigNumber.ToBig(block["max_hp"])

	return block
	
func ApplyTapDamage(block_uid: String) -> void:
	var lane_index := _FindLaneIndexByFrontBlockUid(block_uid)
	if lane_index == -1:
		return
	var lane_data = GlobalSave.save_data.lanes[lane_index]
	if !lane_data.auto_dig_unlocked:
		return
	if lane_data.block_data.is_empty():
		return
	if str(lane_data.block_data[0].uid) != str(block_uid):
		return
	var tap_damage := GlobalStats.GetTapDamage()
	if !lane_data.block_data.has("is_boss"):
		tap_damage = int(tap_damage * GlobalStats.GetFrontBlockTapDmgMulti())
	elif !lane_data.block_data.is_boss:
		tap_damage = int(tap_damage * GlobalStats.GetFrontBlockTapDmgMulti())
	
	_ApplyDamageToFrontBlock(lane_index, tap_damage, true)

func _FindLaneIndexByFrontBlockUid(block_uid: String) -> int:
	for i in range(GlobalSave.save_data.lanes.size()):
		var lane = GlobalSave.save_data.lanes[i]
		if lane.block_data.is_empty():
			continue
		if str(lane.block_data[0].uid) == str(block_uid):
			return i
	return -1
	
func _ApplyDamageToFrontBlock(lane_index: int, damage: float, is_tap_damage: bool = false) -> bool:
	if lane_index < 0 or lane_index >= GlobalSave.save_data.lanes.size():
		return false

	var lane = GlobalSave.save_data.lanes[lane_index]
	if lane.block_data.is_empty():
		return false

	var current_block = lane.block_data[0]
	var is_boss := bool(current_block.get("is_boss", false))

	var destroy_context := {
		"reward_mult": 1.0,
		"did_tap_execute": false,
		"did_tap_crit": false
	}

	if is_boss:
		damage = GlobalStats.ApplyBossDamageMultiplier(damage)

		var damage_result := _GetBossDamageResult(current_block, damage, is_tap_damage)
		damage = float(damage_result.get("damage", 0.0))

		if bool(damage_result.get("blocked", false)):
			boss_special_blocked_hit.emit(
				lane_index,
				str(current_block.get("uid", "")),
				str(damage_result.get("reason", ""))
			)
			return false

	var min_hit_damage := float(current_block.get("min_hit_damage", 0.0))
	if min_hit_damage > 0.0 and damage < min_hit_damage:
		return false

	if damage <= 0.0:
		return false

	if is_tap_damage:
		if !is_boss and _CanTapExecuteBlock(current_block):
			damage = GlobalBigNumber.ToFloatSafe(current_block.get("hp", 0.0))
			destroy_context["did_tap_execute"] = true
			destroy_context["reward_mult"] = GlobalStats.GetTapExecuteRewardMultiplier()
		else:
			var tap_crit_result := GlobalStats.ApplyTapCritToDamage(damage)
			damage = float(tap_crit_result.get("damage", damage))
			destroy_context["did_tap_crit"] = bool(tap_crit_result.get("did_crit", false))
	else:
		var crit_result := GlobalStats.ApplyCritToDamage(damage)
		damage = float(crit_result.get("damage", damage))

	var hp_big := GlobalBigNumber.ToBig(current_block.get("hp", 0.0))
	var damage_big := GlobalBigNumber.ToBig(damage)

	current_block["hp"] = GlobalBigNumber.Sub(hp_big, damage_big)

	_EmitBlockHpUpdated(lane_index)

	if GlobalBigNumber.Compare(current_block["hp"], GlobalBigNumber.Zero()) > 0:
		return false

	var destroyed_uid := str(current_block.uid)
	block_destroyed.emit(lane_index, destroyed_uid)

	if current_block.has("is_boss") and current_block.is_boss:
		GlobalSave.SetTotalBossKills(1)

		GlobalDailyQuest.RegisterBossDefeated(
			str(current_block.get("boss_id", "")),
			str(current_block.get("type", "boss"))
		)
	else:
		GlobalDailyQuest.RegisterBlockBroken(current_block.id, current_block.id)
	_FinishFrontBlock(lane_index, destroy_context)
	return true


func IsLaneCurrentBlockBoss(lane_index: int) -> bool:
	var block = GetLaneCurrentBlock(lane_index)
	if block.is_empty():
		return false
	return bool(block.get("is_boss", false))
	
func GetLaneCurrentBossID(lane_index: int) -> String:
	var block = GetLaneCurrentBlock(lane_index)
	if block.is_empty():
		return ""
	if !bool(block.get("is_boss", false)):
		return ""
	return str(block.get("boss_id", ""))

func _HandleBossBlockFinished(finished_block: Dictionary) -> void:
	var boss_id := str(finished_block.get("boss_id", ""))
	var boss_name := str(finished_block.get("name", boss_id))

	var rewards = GlobalBossDb.OnBossKilled(finished_block)
	if rewards.is_empty():
		return

	var final_coins := int(rewards.get("coins", 0))
	if final_coins > 0:
		final_coins = int(round(final_coins * GlobalStats.GetCoinYieldMultiplier()))
		rewards["coins"] = final_coins


	if !rewards.has("relic_ids") or typeof(rewards["relic_ids"]) != TYPE_ARRAY:
		rewards["relic_ids"] = []

	var chest_data = GlobalRewardChest.MakeBossRewardChest(boss_id, boss_name, rewards)
	GlobalRewardChest.AddChest(chest_data)

func GetLaneCurrentBlockDisplayName(lane_index: int) -> String:
	var block = GetLaneCurrentBlock(lane_index)
	if block.is_empty():
		return ""
	if bool(block.get("is_boss", false)):
		return "BOSS: " + str(block.get("name", "Unknown Boss"))
	return str(block.get("name", ""))
	
func GetLaneCurrentBlockType(lane_index: int) -> String:
	var block = GetLaneCurrentBlock(lane_index)
	if block.is_empty():
		return ""
	if bool(block.get("is_boss", false)):
		return "boss"
	return str(block.get("type", "block"))

func GenerateNextBlocksForLane(lane_index: int) -> void:
	if lane_index < 0 or lane_index >= GlobalSave.save_data.lanes.size():
		return

	var lane = GlobalSave.save_data.lanes[lane_index]
	var blocks_to_generate := 5
	var start_depth := int(lane.lane_depth)

	for i in range(blocks_to_generate):
		var block_depth := start_depth + i
		var new_block = CreateGeneratedBlockForDepth(lane_index, block_depth)
		if !new_block.is_empty():
			lane.block_data.append(new_block)

func _EnsureBossRuntime(block: Dictionary, boss_data: Dictionary) -> Dictionary:
	if !block.has("boss_runtime") or typeof(block["boss_runtime"]) != TYPE_DICTIONARY:
		block["boss_runtime"] = {}

	var runtime: Dictionary = block["boss_runtime"]
	var special_values: Dictionary = boss_data.get("special_values", {})

	if !runtime.has("elapsed_sec"):
		runtime["elapsed_sec"] = 0.0

	if !runtime.has("enraged"):
		runtime["enraged"] = false

	if !runtime.has("shield_active"):
		runtime["shield_active"] = false

	if !runtime.has("shield_time_left"):
		runtime["shield_time_left"] = 0.0

	if !runtime.has("shield_cooldown_left"):
		runtime["shield_cooldown_left"] = float(special_values.get("shield_cooldown_sec", 0.0))

	return runtime
	
func _ProcessBossSpecial(lane_index: int, delta: float) -> void:
	if lane_index < 0 or lane_index >= GlobalSave.save_data.lanes.size():
		return

	var lane = GlobalSave.save_data.lanes[lane_index]
	if lane.block_data.is_empty():
		return

	var block = lane.block_data[0]
	if !bool(block.get("is_boss", false)):
		return

	var boss_id := str(block.get("boss_id", ""))
	var boss_data: Dictionary = GlobalBossDb.GetBossDataByID(boss_id)
	if boss_data.is_empty():
		return

	var special_type := str(boss_data.get("special_type", "none"))
	var special_values: Dictionary = boss_data.get("special_values", {})

	if !block.has("boss_runtime") or typeof(block["boss_runtime"]) != TYPE_DICTIONARY:
		block["boss_runtime"] = {}

	var runtime: Dictionary = block["boss_runtime"]

	if !runtime.has("elapsed_sec"):
		runtime["elapsed_sec"] = 0.0
	if !runtime.has("enraged"):
		runtime["enraged"] = false
	if !runtime.has("shield_active"):
		runtime["shield_active"] = false
	if !runtime.has("shield_time_left"):
		runtime["shield_time_left"] = 0.0
	if !runtime.has("shield_cooldown_left"):
		runtime["shield_cooldown_left"] = float(special_values.get("shield_cooldown_sec", 0.0))

	runtime["elapsed_sec"] = float(runtime.get("elapsed_sec", 0.0)) + delta

	var old_hp := GlobalBigNumber.ToBig(block.get("hp", 0.0))
	var max_hp := GlobalBigNumber.ToBig(block.get("max_hp", 1.0))
	var new_hp := old_hp.duplicate(true)

	match special_type:
		"regen":
			var regen_percent := float(special_values.get("regen_percent_per_sec", 0.0) * GlobalStats.GetBossRegenReduction())
			var regen_amount := GlobalBigNumber.MulFloat(max_hp, regen_percent * delta)
			new_hp = GlobalBigNumber.Add(new_hp, regen_amount)
		"timer_enrage":
			var enrage_after := float(special_values.get("enrage_after_sec", 999999.0))

			if float(runtime.get("elapsed_sec", 0.0)) >= enrage_after:
				runtime["enraged"] = true

			if bool(runtime.get("enraged", false)):
				var extra_regen := float(special_values.get("extra_regen_percent_per_sec", 0.0) * GlobalStats.GetBossRegenReduction())
				var extra_regen_amount := GlobalBigNumber.MulFloat(max_hp, extra_regen * delta)
				new_hp = GlobalBigNumber.Add(new_hp, extra_regen_amount)

		"shield_cycle":
			if bool(runtime.get("shield_active", false)):
				runtime["shield_time_left"] = max(0.0, float(runtime.get("shield_time_left", 0.0)) - delta)

				if float(runtime["shield_time_left"]) <= 0.0:
					runtime["shield_active"] = false
					runtime["shield_cooldown_left"] = float(special_values.get("shield_cooldown_sec", 0.0))
			else:
				runtime["shield_cooldown_left"] = max(0.0, float(runtime.get("shield_cooldown_left", 0.0)) - delta)

				if float(runtime["shield_cooldown_left"]) <= 0.0:
					runtime["shield_active"] = true
					runtime["shield_time_left"] = float(special_values.get("shield_duration_sec", 0.0))

		_:
			return


	if GlobalBigNumber.Compare(new_hp, max_hp) > 0:
		new_hp = max_hp.duplicate(true)

	if special_type == "timer_enrage":
		if GlobalBigNumber.Compare(new_hp, max_hp) >= 0:
			runtime["elapsed_sec"] = 0.0
			runtime["enraged"] = false

	if GlobalBigNumber.Compare(new_hp, old_hp) != 0:
		block["hp"] = new_hp
		_EmitBlockHpUpdated(lane_index)
		
func _GetBossDamageResult(block: Dictionary, damage: float, is_tap_damage: bool) -> Dictionary:
	var boss_id := str(block.get("boss_id", ""))
	var boss_data: Dictionary = GlobalBossDb.GetBossDataByID(boss_id)
	if boss_data.is_empty():
		return {
			"damage": damage,
			"blocked": false,
			"reason": ""
		}

	var runtime := _EnsureBossRuntime(block, boss_data)
	var special_type := str(boss_data.get("special_type", "none"))
	var special_values: Dictionary = boss_data.get("special_values", {})

	match special_type:
		"armor":
			var reduction := float(special_values.get("damage_reduction_percent", 0.0))
			damage *= max(0.0, 1.0 - reduction)

		"tap_resist":
			if is_tap_damage:
				var tap_mult := float(special_values.get("tap_damage_multiplier", 1.0))
				damage *= tap_mult

		"shield_cycle":
			if bool(runtime.get("shield_active", false)):
				return {
					"damage": 0.0,
					"blocked": true,
					"reason": "shield"
				}

		_:
			pass

	return {
		"damage": max(0.0, damage),
		"blocked": false,
		"reason": ""
	}

func _RollBossRelicDrop(drop_table: Array) -> String:
	if drop_table.is_empty():
		return ""

	var valid_ids: Array = []
	for entry in drop_table:
		var relic_id := str(entry)
		if relic_id == "":
			continue
		if !GlobalRelicDb.HasRelicData(relic_id):
			continue
		valid_ids.append(relic_id)

	if valid_ids.is_empty():
		return ""

	return str(valid_ids[randi() % valid_ids.size()])


func _HandleBossDrops(drop_table: Array) -> String:
	var relic_id := _RollBossRelicDrop(drop_table)
	if relic_id == "":
		return ""

	GlobalRelicDb.AddOwnedRelic(relic_id, 1)
	return relic_id

func _GrantFirstKillRandomRelic(boss_id: String) -> String:
	if boss_id == "":
		return ""

	var relic_id := GlobalRelicDb.GetRandomRelicID()
	if relic_id == "":
		return ""

	GlobalRelicDb.AddOwnedRelic(relic_id, 1)
	return relic_id

func _CanTapExecuteBlock(block: Dictionary) -> bool:
	if bool(block.get("is_boss", false)):
		return false

	var threshold := GlobalStats.GetTapExecuteThreshold()
	if threshold <= 0.0:
		return false

	var max_hp = max(1.0, float(block.get("max_hp", block.get("hp", 1.0))))
	var current_hp = max(0.0, float(block.get("hp", 0.0)))

	return current_hp <= max_hp * threshold

func _GrantRolledBlockDrops(finished_block: Dictionary, reward_mult: float = 1.0) -> void:
	var block_id := str(finished_block.get("id", ""))
	if block_id == "":
		return

	var rolled_drops: Dictionary = GlobalBlockDatabase.RollBlockDrops(finished_block, reward_mult)

	for currency in rolled_drops.keys():
		var amount := int(rolled_drops.get(currency, 0))
		if amount <= 0:
			continue

		if currency == "coins":
			amount = int(round(float(amount) * GlobalStats.GetCoinYieldMultiplier()))

		GlobalSave.AddCurrency(currency, amount)
