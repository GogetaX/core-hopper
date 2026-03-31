extends Node

signal block_hp_updated(lane_index: int, block_uid: String, hp: float, max_hp: float, hp_percent: float)
signal block_destroyed(lane_index: int, block_uid: String)

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
	SyncDiggingLanes()
	set_process(true)


func _process(delta: float) -> void:
	for lane_index in _lane_runtime.keys().duplicate():
		_ProcessLane(int(lane_index), delta)


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
	if lane.block_data.is_empty():
		return

	var block = lane.block_data[0]
	var hp := float(block.hp)
	var max_hp := float(block.max_hp)
	var hp_percent = hp / max(max_hp, 0.001)

	block_hp_updated.emit(
		lane_index,
		str(block.uid),
		hp,
		max_hp,
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
		_lane_runtime.erase(lane_index)
		return

	if !_lane_runtime.has(lane_index):
		_SyncLaneRuntime(lane_index)
		if !_lane_runtime.has(lane_index):
			return

	var runtime: Dictionary = _lane_runtime[lane_index]
	var current_block = lane.block_data[0]

	if str(current_block.uid) != str(runtime["current_block_uid"]):
		_SyncLaneRuntime(lane_index)
		if !_lane_runtime.has(lane_index):
			return
		runtime = _lane_runtime[lane_index]
		current_block = lane.block_data[0]

	var hit_interval := _GetHitInterval(float(runtime["dig_speed"]))
	runtime["hit_progress"] += delta

	while runtime["hit_progress"] >= hit_interval and lane.block_data.size() > 0:
		runtime["hit_progress"] -= hit_interval

		current_block.hp = max(
			0.0,
			float(current_block.hp) - float(runtime["dig_power"])
		)

		_EmitBlockHpUpdated(lane_index)

		if current_block.hp <= 0.0:
			var destroyed_uid := str(current_block.uid)
			block_destroyed.emit(lane_index, destroyed_uid)

			_FinishFrontBlock(lane_index)

			if lane.block_data.is_empty():
				_lane_runtime.erase(lane_index)
				return

			current_block = lane.block_data[0]
			runtime["current_block_uid"] = str(current_block.uid)
			runtime["hit_progress"] = 0.0

			# optional: emit once for the new front block
			_EmitBlockHpUpdated(lane_index)
			
			break

	_lane_runtime[lane_index] = runtime


func _FinishFrontBlock(lane_index: int) -> void:
	var lane = GlobalSave.save_data.lanes[lane_index]
	if lane.block_data.is_empty():
		return

	var finished_block = lane.block_data[0]
	var final_coins = finished_block.reward_amount
	if finished_block.reward_type == "coins":
		final_coins = int(round(finished_block.reward_amount * GlobalStats.GetCoinYieldMultiplier()))
	GlobalSave.AddCurrency(
		str(finished_block.reward_type),
		int(final_coins)
	)

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
	lane.block_data[0].hp = float(lane.block_data[0].max_hp)

	if _lane_runtime.has(lane_index):
		_lane_runtime[lane_index]["hit_progress"] = 0.0
		_lane_runtime[lane_index]["current_block_uid"] = str(lane.block_data[0].uid)
	_EmitBlockHpUpdated(lane_index)

func _FindBotByUid(bot_uid: int) -> Dictionary:
	for bot in GlobalSave.save_data.bot_inventory.bot_db:
		if int(bot.uid) == bot_uid:
			return bot
	return {}


func _GetBotDigPower(bot: Dictionary) -> float:
	# replace with your real stat curve
	if bot.has("stats") and bot["stats"].has("dig_power"):
		return float(bot["stats"]["dig_power"])

	var level := int(bot.get("level", 1))
	return GlobalStats.GetBotStats(level).dig_power


func _GetBotDigSpeed(bot: Dictionary) -> float:
	# replace with your real stat curve
	if bot.has("stats") and bot["stats"].has("dig_speed"):
		return float(bot["stats"]["dig_speed"])

	var level := int(bot.get("level", 1))
	return GlobalStats.GetBotStats(level).dig_speed


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
	return float(block.hp)


func GetLaneCurrentMaxHp(lane_index: int) -> float:
	var block = GetLaneCurrentBlock(lane_index)
	if block.is_empty():
		return 0.0
	return float(block.max_hp)


func GetLaneCurrentHpLeftPercent(lane_index: int) -> float:
	var block = GetLaneCurrentBlock(lane_index)
	if block.is_empty():
		return 0.0

	var max_hp := float(block.max_hp)
	if max_hp <= 0.0:
		return 0.0

	return float(block.hp) / max_hp


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
		"hp": float(block.hp),
		"max_hp": float(block.max_hp),
		"hp_percent": float(block.hp) / max(float(block.max_hp), 0.001)
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
		return

	_SyncLaneRuntime(lane_index)
	_EmitBlockHpUpdated(lane_index)


func GenerateNextBlocksForLane(lane_index: int) -> void:
	if lane_index < 0 or lane_index >= GlobalSave.save_data.lanes.size():
		return

	var lane = GlobalSave.save_data.lanes[lane_index]

	var blocks_to_generate := 5
	var start_depth := int(lane.lane_depth)

	for i in range(blocks_to_generate):
		var block_depth := start_depth + i
		var new_block = GlobalBlockDatabase.CreateBlockForLane(block_depth, lane_index)
		lane.block_data.append(new_block)
		
func ApplyTapDamage(block_uid: String) -> void:
	var lane_index := _FindLaneIndexByFrontBlockUid(block_uid)
	if lane_index == -1:
		return

	var lane_data = GlobalSave.save_data.lanes[lane_index]
	if lane_data.is_empty():
		return
	if !lane_data.auto_dig_unlocked:
		return
	if int(lane_data.bot_uid) == -1:
		return
	if lane_data.block_data.is_empty():
		return
	if str(lane_data.block_data[0].uid) != str(block_uid):
		return

	var bot_data = GlobalSave.GetBotDataFromUID(int(lane_data.bot_uid))
	if bot_data.is_empty():
		return

	var bot_stats = GlobalStats.GetBotStats(int(bot_data.level))
	var tap_dps = float(bot_stats.dig_power) * float(GlobalStats.GetUpgradeValue("tap_damage"))

	_ApplyDamageToFrontBlock(lane_index, tap_dps)

func _FindLaneIndexByFrontBlockUid(block_uid: String) -> int:
	for i in range(GlobalSave.save_data.lanes.size()):
		var lane = GlobalSave.save_data.lanes[i]
		if lane.block_data.is_empty():
			continue
		if str(lane.block_data[0].uid) == str(block_uid):
			return i
	return -1
	
func _ApplyDamageToFrontBlock(lane_index: int, damage: float) -> bool:
	if lane_index < 0 or lane_index >= GlobalSave.save_data.lanes.size():
		return false

	var lane = GlobalSave.save_data.lanes[lane_index]
	if lane.block_data.is_empty():
		return false

	var current_block = lane.block_data[0]
	current_block.hp = max(0.0, float(current_block.hp) - float(damage))

	_EmitBlockHpUpdated(lane_index)

	if current_block.hp > 0.0:
		return false

	var destroyed_uid := str(current_block.uid)
	block_destroyed.emit(lane_index, destroyed_uid)

	_FinishFrontBlock(lane_index)

	if lane.block_data.is_empty():
		_lane_runtime.erase(lane_index)
		return true

	if _lane_runtime.has(lane_index):
		_lane_runtime[lane_index]["current_block_uid"] = str(lane.block_data[0].uid)
		_lane_runtime[lane_index]["hit_progress"] = 0.0

	_EmitBlockHpUpdated(lane_index)
	return true
