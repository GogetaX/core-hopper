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

	var capped_seconds := mini(offline_seconds, GetOfflineCapSeconds())
	var efficiency := GetOfflineEfficiency()

	var result := _SimulateOfflineSeconds(capped_seconds, efficiency)
	result["did_collect"] = true
	result["offline_seconds"] = offline_seconds
	result["capped_seconds"] = capped_seconds
	
	result.coins = int(result.coins * GlobalStats.GetCoinYieldMultiplier())
	
	return result


func GetOfflineCapSeconds(plus_level:int = 0) -> int:
	var level := int(GlobalSave.save_data.global_upgrades.offline_gain_level)+plus_level
	var res : int = OFFLINE_BASE_CAP_SECONDS + (level * 1800)
	return int(res*GlobalStats.GetUpgradeValue("offline_efficiency"))


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

		var bot = _FindBotByUid(int(lane.bot_uid))
		if bot.is_empty():
			continue

		var level := int(bot.get("level", 1))
		var lane_dps = GlobalStats.GetBotStats(level).dig_power * efficiency

		_SimulateLaneOffline(lane_index, lane_dps, seconds, rewards)

	return rewards


func _SimulateLaneOffline(lane_index: int, lane_dps: float, seconds: int, rewards: Dictionary) -> void:
	if lane_dps <= 0.0:
		return

	var remaining_damage := lane_dps * float(seconds)
	var lane = GlobalSave.save_data.lanes[lane_index]

	while remaining_damage > 0.0:
		if lane.block_data.is_empty():
			GlobalDiggingProcess.GenerateNextBlocksForLane(lane_index)
			if lane.block_data.is_empty():
				return

		var block = lane.block_data[0]
		var block_hp := float(block.hp)

		if remaining_damage >= block_hp:
			remaining_damage -= block_hp

			var reward_type := str(block.reward_type)
			var reward_amount := int(block.reward_amount)

			if rewards.has(reward_type):
				rewards[reward_type] += reward_amount
			else:
				rewards[reward_type] = reward_amount

			lane.block_data.remove_at(0)
		else:
			block.hp = block_hp - remaining_damage
			remaining_damage = 0.0


func _FindBotByUid(bot_uid: int) -> Dictionary:
	for bot in GlobalSave.save_data.bot_inventory.bot_db:
		if int(bot.uid) == bot_uid:
			return bot
	return {}
