extends Node

const OFFLINE_MIN_SECONDS := 60
const OFFLINE_BASE_CAP_SECONDS := 7200
const OFFLINE_MAX_EFFICIENCY := 0.85


func ProcessOfflineProgress() -> Dictionary:
	var now_unix := Time.get_unix_time_from_system()
	var last_saved := float(GlobalSave.save_data.meta.last_saved_unix)
	var offline_seconds = max(0, int(now_unix - last_saved))

	if offline_seconds < OFFLINE_MIN_SECONDS:
		return {
			"did_collect": false,
			"offline_seconds": offline_seconds,
			"capped_seconds": 0,
			"coins": 0,
			"crystals": 0,
			"energy": 0,
			"drop_data": []
		}

	var capped_seconds := mini(offline_seconds, GlobalStats.GetOfflineCapSeconds())
	var efficiency := GlobalStats.GetOfflineEfficiency()

	var result := _SimulateOfflineSeconds(capped_seconds, efficiency)
	result["coins"] = int(result["coins"] * GlobalStats.GetOfflineCoinGain())
	result["crystals"] = int(result["crystals"] * GlobalStats.GetOfflineCrystalGain())
	result["energy"] = int(result["energy"] * GlobalStats.GetOfflineEnergyGain())
	result["did_collect"] = true
	result["offline_seconds"] = offline_seconds
	result["capped_seconds"] = capped_seconds

	# keep your current final coin multiplier behavior
	result.coins = int(result.coins * GlobalStats.GetCoinYieldMultiplier())

	return result


func GetOfflineCapSeconds(plus_level: int = 0) -> int:
	var level := int(GlobalSave.save_data.global_upgrades.offline_gain_level) + plus_level
	var res: int = OFFLINE_BASE_CAP_SECONDS + (level * 1800)
	return int(res * GlobalStats.GetUpgradeValue("offline_efficiency"))

func GetOfflineEfficiency() -> float:
	var level := int(GlobalSave.save_data.global_upgrades.offline_gain_level)
	return min(OFFLINE_MAX_EFFICIENCY, 0.35 + (level * 0.10))


func _SimulateOfflineSeconds(seconds: int, efficiency: float) -> Dictionary:
	var rewards := {
		"coins": 0,
		"crystals": 0,
		"energy": 0,
		"drop_data": []
	}

	for lane_index in range(GlobalSave.save_data.lanes.size()):
		var lane = GlobalSave.save_data.lanes[lane_index]

		if !lane.auto_dig_unlocked:
			continue

		if int(lane.bot_uid) == -1:
			continue

		var harvest_depth := int(lane.get("last_cleared_depth", -1))
		if harvest_depth < 0:
			continue

		var bot = _FindBotByUid(int(lane.bot_uid))
		if bot.is_empty():
			continue

		var level := int(bot.get("level", 1))
		var lane_dps := GlobalStats.GetBotExpectedDps(level) * efficiency

		_HarvestLaneOffline(lane_index, harvest_depth, lane_dps, seconds, rewards)

	return rewards


func _SimulateLaneOffline(lane_index: int, lane_dps: float, seconds: int, rewards: Dictionary) -> void:
	if lane_dps <= 0.0:
		return

	var remaining_damage := lane_dps * float(seconds)
	var lane = GlobalSave.save_data.lanes[lane_index]

	while remaining_damage > 0.0:
		if lane.block_data.is_empty():
			var new_block = GlobalDiggingProcess.CreateGeneratedBlockForDepth(
				lane_index,
				int(lane.lane_depth)
			)
			if new_block.is_empty():
				return
			lane.block_data.append(new_block)

		var block = lane.block_data[0]

		# bosses are online-only
		if bool(block.get("is_boss", false)):
			return

		var block_hp := float(block.hp)

		if remaining_damage >= block_hp:
			remaining_damage -= block_hp

			var rolled_drops := GlobalBlockDatabase.RollBlockDrops(block, 1.0)
			_AddRolledDropsToRewards(rewards, rolled_drops)

			lane.lane_depth = int(lane.lane_depth) + 1
			GlobalSave.SetGlobalDepth(int(lane.lane_depth))
			lane.block_data.remove_at(0)
		else:
			block.hp = block_hp - remaining_damage
			remaining_damage = 0.0


func _HarvestLaneOffline(
	lane_index: int,
	harvest_depth: int,
	lane_dps: float,
	seconds: int,
	rewards: Dictionary
) -> void:
	if lane_dps <= 0.0 or seconds <= 0:
		return

	# IMPORTANT:
	# Use the normal block database directly.
	# This avoids boss generation and keeps offline as passive harvest only.
	var sample_block := GlobalBlockDatabase.CreateBlockForLane(harvest_depth, lane_index)
	if sample_block.is_empty():
		return

	var virtual_hp = max(
		1.0,
		float(sample_block.get("max_hp", sample_block.get("hp", 1.0)))
	)

	var total_damage := lane_dps * float(seconds)
	var harvest_ratio = total_damage / virtual_hp
	if harvest_ratio <= 0.0:
		return

	# Only roll drops for whole completed blocks.
	# Partial progress should not roll crystals/energy.
	var whole_blocks := maxi(0, int(floor(harvest_ratio)))
	if whole_blocks <= 0:
		return

	for i in range(whole_blocks):
		var rolled_drops = GlobalBlockDatabase.RollBlockDrops(sample_block, 1.0)
		_AddRolledDropsToRewards(rewards, rolled_drops)

func _FindBotByUid(bot_uid: int) -> Dictionary:
	for bot in GlobalSave.save_data.bot_inventory.bot_db:
		if int(bot.uid) == bot_uid:
			return bot
	return {}
	
func _AddRolledDropsToRewards(rewards: Dictionary, rolled_drops: Dictionary) -> void:
	for currency in rolled_drops.keys():
		var amount := int(rolled_drops.get(currency, 0))
		if amount <= 0:
			continue

		rewards[currency] = int(rewards.get(currency, 0)) + amount
