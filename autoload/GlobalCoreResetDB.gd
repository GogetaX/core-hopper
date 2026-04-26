extends Node

const CORE_RESET_DB_PATH := "res://data/core_reset/core_reset.json"

var core_reset_db: Dictionary = {}
var _tier_levels: Array = []


func _ready() -> void:
	LoadCoreResetDatabase()


func LoadCoreResetDatabase(path: String = CORE_RESET_DB_PATH) -> bool:
	core_reset_db.clear()
	_tier_levels.clear()

	if !FileAccess.file_exists(path):
		push_warning("LoadCoreResetDatabase: file not found -> " + path)
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("LoadCoreResetDatabase: failed to open -> " + path)
		return false

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_warning("LoadCoreResetDatabase: invalid json -> " + path)
		return false

	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("LoadCoreResetDatabase: root must be a dictionary")
		return false

	var tiers_data = data.get("tiers", {})
	if typeof(tiers_data) != TYPE_DICTIONARY:
		push_warning("LoadCoreResetDatabase: missing tiers dictionary")
		return false

	var normalized_tiers: Dictionary = {}

	for tier_key in tiers_data.keys():
		var tier_level := int(str(tier_key))
		if tier_level <= 0:
			continue

		var tier_data = tiers_data[tier_key]
		if typeof(tier_data) != TYPE_DICTIONARY:
			continue

		var entry: Dictionary = tier_data.duplicate(true)
		entry["tier"] = tier_level
		entry["id"] = str(tier_level)
		entry["required_depth"] = maxi(0, int(entry.get("required_depth", 0)))

		if !entry.has("effects") or typeof(entry.get("effects", [])) != TYPE_ARRAY:
			entry["effects"] = []

		normalized_tiers[str(tier_level)] = entry
		_tier_levels.append(tier_level)

	_tier_levels.sort()

	core_reset_db = data.duplicate(true)
	core_reset_db["tiers"] = normalized_tiers

	return !_tier_levels.is_empty()


func _EnsureLoaded() -> void:
	if core_reset_db.is_empty() or _tier_levels.is_empty():
		LoadCoreResetDatabase()


func _EnsureSaveSchema() -> void:
	if !GlobalSave.save_data.has("player_stats") or typeof(GlobalSave.save_data.player_stats) != TYPE_DICTIONARY:
		GlobalSave.save_data["player_stats"] = {}

	var stats: Dictionary = GlobalSave.save_data.player_stats

	if !stats.has("max_depth_reached"):
		stats["max_depth_reached"] = 0

	if !stats.has("core_resets"):
		stats["core_resets"] = 0

	if !stats.has("current_prestige"):
		stats["current_prestige"] = 0

	GlobalSave.save_data["player_stats"] = stats


func IsCoreResetDatabaseLoaded() -> bool:
	return !_tier_levels.is_empty()


func GetMaxResetLevel() -> int:
	_EnsureLoaded()

	if _tier_levels.is_empty():
		return 0

	return int(_tier_levels[_tier_levels.size() - 1])


func GetCurrentResetLevel() -> int:
	_EnsureSaveSchema()

	var current_level := maxi(0, int(GlobalSave.save_data.player_stats.get("core_resets", 0)))
	var max_level := GetMaxResetLevel()

	if max_level <= 0:
		return current_level

	return mini(current_level, max_level)


func GetNextResetLevel() -> int:
	var next_level := GetCurrentResetLevel() + 1
	if next_level > GetMaxResetLevel():
		return 0
	return next_level


func GetResetDataByLevel(level: int) -> Dictionary:
	_EnsureLoaded()

	if level <= 0:
		return {}

	var tiers: Dictionary = core_reset_db.get("tiers", {})
	var key := str(level)

	if !tiers.has(key):
		return {}

	var tier_data = tiers[key]
	if typeof(tier_data) != TYPE_DICTIONARY:
		return {}

	return tier_data.duplicate(true)


func GetCurrentResetData() -> Dictionary:
	var current_level := GetCurrentResetLevel()
	if current_level <= 0:
		return {}

	return GetResetDataByLevel(current_level)


func GetNextResetData() -> Dictionary:
	var next_level := GetNextResetLevel()
	if next_level <= 0:
		return {}

	return GetResetDataByLevel(next_level)


func HasNextReset() -> bool:
	return GetNextResetLevel() > 0


func IsMaxResetReached() -> bool:
	var max_level := GetMaxResetLevel()
	return max_level > 0 and GetCurrentResetLevel() >= max_level


func GetBestDepthReached() -> int:
	_EnsureSaveSchema()
	return maxi(0, int(GlobalSave.save_data.player_stats.get("max_depth_reached", 0)))


func CanClaimNextReset() -> bool:
	var next_data := GetNextResetData()
	if next_data.is_empty():
		return false

	return GetBestDepthReached() >= int(next_data.get("required_depth", 0))


func GetRemainingDepthToNextReset() -> int:
	var next_data := GetNextResetData()
	if next_data.is_empty():
		return 0

	var required_depth := int(next_data.get("required_depth", 0))
	return maxi(0, required_depth - GetBestDepthReached())


func GetProgressToNextReset() -> Dictionary:
	var current_depth := GetBestDepthReached()
	var next_data := GetNextResetData()

	if next_data.is_empty():
		return {
			"current_depth": current_depth,
			"required_depth": current_depth,
			"remaining_depth": 0,
			"progress": 1.0,
			"is_maxed": true
		}

	var required_depth := maxi(1, int(next_data.get("required_depth", 1)))
	var progress = clamp(float(current_depth) / float(required_depth), 0.0, 1.0)

	return {
		"current_depth": current_depth,
		"required_depth": required_depth,
		"remaining_depth": maxi(0, required_depth - current_depth),
		"progress": progress,
		"is_maxed": false
	}


func BuildAcquiredCoreResetSummary() -> Dictionary:
	_EnsureLoaded()

	var claimed_level := GetCurrentResetLevel()
	var stats: Dictionary = {}
	var unlock_features: Dictionary = {}
	var claimed_tiers: Array = []

	for level_value in _tier_levels:
		var level := int(level_value)
		if level > claimed_level:
			break

		var tier_data := GetResetDataByLevel(level)
		if tier_data.is_empty():
			continue

		claimed_tiers.append(tier_data)

		var effects = tier_data.get("effects", [])
		if typeof(effects) != TYPE_ARRAY:
			continue

		for effect in effects:
			if typeof(effect) != TYPE_DICTIONARY:
				continue

			var kind := str(effect.get("kind", "")).strip_edges().to_lower()

			match kind:
				"stat":
					var stat_name := str(effect.get("stat", ""))
					if stat_name == "":
						continue

					if !stats.has(stat_name):
						stats[stat_name] = 0.0

					stats[stat_name] = float(stats.get(stat_name, 0.0)) + float(effect.get("value", 0.0))

				"unlock":
					var feature := str(effect.get("feature", ""))
					if feature == "":
						continue

					unlock_features[feature] = true

	return {
		"stats": stats,
		"unlock_features": unlock_features,
		"claimed_tiers": claimed_tiers,
		"claimed_reset_count": claimed_level,
		"is_maxed": IsMaxResetReached()
	}


func BuildFlatAcquiredCoreResetStats() -> Dictionary:
	var summary := BuildAcquiredCoreResetSummary()
	return summary.get("stats", {}).duplicate(true)


func GetCoreResetStatValue(stat_name: String) -> float:
	if stat_name == "":
		return 0.0

	var stats: Dictionary = BuildFlatAcquiredCoreResetStats()
	return float(stats.get(stat_name, 0.0))

func _FormatCoreResetNumber(value: float) -> String:
	var rounded := snappedf(value, 0.1)
	if is_equal_approx(rounded, round(rounded)):
		return str(int(round(rounded)))
	return str(rounded)


func GetCoreResetStatTitle(stat_name: String) -> String:
	match stat_name.strip_edges().to_lower():
		"merge_slot_bonus":
			return "Merge Slots"
		"bot_buy_start_level_bonus":
			return "Starting Bot Level"
		"relic_slot_bonus":
			return "Relic Slots"
		"bot_power_mult":
			return "Bot Power"
		"resource_drop_mult":
			return "Resource Drops"
		"boss_reward_mult":
			return "Boss Rewards"
		"tap_damage_mult":
			return "Tap Damage"
		_:
			return stat_name.capitalize()


func GetCoreResetEffectBonusStr(effect: Dictionary, include_total: bool = false) -> String:
	if typeof(effect) != TYPE_DICTIONARY:
		return ""

	var kind := str(effect.get("kind", "")).strip_edges().to_lower()
	if kind != "stat":
		return ""

	var stat_name := str(effect.get("stat", "")).strip_edges().to_lower()
	if stat_name == "":
		return ""

	var effect_value := float(effect.get("value", 0.0))
	var current_total := GetCoreResetStatValue(stat_name)
	var next_total := current_total + effect_value

	match stat_name:
		"merge_slot_bonus":
			var slot_word := "Merge Slot"
			if int(round(effect_value)) != 1:
				slot_word = "Merge Slots"

			if include_total:
				return "+" + str(int(round(effect_value))) + " " + slot_word + "  Total: +" + str(int(round(next_total)))
			return "+" + str(int(round(effect_value))) + " " + slot_word

		"bot_buy_start_level_bonus":
			var start_level := int(round(next_total))
			return "Start with level +" + str(start_level) + " Bots"

		"relic_slot_bonus":
			var relic_word := "Relic Slot"
			if int(round(effect_value)) != 1:
				relic_word = "Relic Slots"

			if include_total:
				return "+" + str(int(round(effect_value))) + " " + relic_word + "  Total: +" + str(int(round(next_total)))
			return "+" + str(int(round(effect_value))) + " " + relic_word

		"bot_power_mult":
			return "+" + _FormatCoreResetNumber(effect_value * 100.0) + "% Bot Power"

		"resource_drop_mult":
			return "+" + _FormatCoreResetNumber(effect_value * 100.0) + "% Resource Drops"

		"boss_reward_mult":
			return "+" + _FormatCoreResetNumber(effect_value * 100.0) + "% Boss Rewards"

		"tap_damage_mult":
			return "+" + _FormatCoreResetNumber(effect_value * 100.0) + "% Tap Damage"

		_:
			if abs(effect_value) >= 1.0 and is_equal_approx(effect_value, round(effect_value)):
				if effect_value > 0.0:
					return "+" + str(int(round(effect_value))) + " " + GetCoreResetStatTitle(stat_name)
				return str(int(round(effect_value))) + " " + GetCoreResetStatTitle(stat_name)

			if effect_value > 0.0:
				return "+" + _FormatCoreResetNumber(effect_value) + " " + GetCoreResetStatTitle(stat_name)
			return _FormatCoreResetNumber(effect_value) + " " + GetCoreResetStatTitle(stat_name)


func GetCoreResetEffectsBonusStr(effects: Array, separator: String = "\n", include_total: bool = false) -> String:
	var parts: Array[String] = []

	for effect in effects:
		if typeof(effect) != TYPE_DICTIONARY:
			continue

		var part := GetCoreResetEffectBonusStr(effect, include_total)
		if part != "":
			parts.append(part)

	return separator.join(parts)


func GetResetDataBonusStr(reset_data: Dictionary, separator: String = "\n", include_total: bool = false) -> String:
	if typeof(reset_data) != TYPE_DICTIONARY or reset_data.is_empty():
		return ""

	var effects = reset_data.get("effects", [])
	if typeof(effects) != TYPE_ARRAY:
		return ""

	return GetCoreResetEffectsBonusStr(effects, separator, include_total)


func GetCurrentResetBonusStr(separator: String = "\n", include_total: bool = false) -> String:
	return GetResetDataBonusStr(GetCurrentResetData(), separator, include_total)


func GetNextResetBonusStr(separator: String = "\n", include_total: bool = false) -> String:
	return GetResetDataBonusStr(GetNextResetData(), separator, include_total)

func ActivateCoreReset() -> bool:
	_EnsureLoaded()
	_EnsureSaveSchema()

	if !CanClaimNextReset():
		return false

	var next_data := GetNextResetData()
	if next_data.is_empty():
		return false

	var next_level := int(next_data.get("tier", GetCurrentResetLevel() + 1))
	var old_reset_count := int(GlobalSave.save_data.player_stats.get("core_resets", 0))
	if next_level <= old_reset_count:
		return false

	# 1) grant the permanent reset tier first
	GlobalSave.save_data.player_stats["core_resets"] = next_level
	GlobalSave.save_data.player_stats["current_prestige"] = next_level

	# 2) wipe current run state, keep meta systems
	_ResetRunStateForCoreReset()

	# 3) rebuild fresh lane blocks for the new run
	if GlobalSave.has_method("RepapulateAllLaneBlocks"):
		GlobalSave.RepapulateAllLaneBlocks()
	else:
		for lane_index in range(GlobalSave.save_data.get("lanes", []).size()):
			var lane_data: Dictionary = GlobalSave.save_data.lanes[lane_index]
			if lane_data.get("block_data", []).is_empty() and GlobalSave.has_method("GenerateNextBlocks"):
				GlobalSave.GenerateNextBlocks(lane_index, 5)

	# 4) refresh digging runtime
	if has_node("/root/GlobalDiggingProcess"):
		var digging = get_node("/root/GlobalDiggingProcess")
		if digging != null:
			if digging.has_method("SyncDiggingLanes"):
				digging.SyncDiggingLanes()
			else:
				for lane_index in range(GlobalSave.save_data.get("lanes", []).size()):
					if digging.has_method("RefreshLaneDigging"):
						digging.RefreshLaneDigging(lane_index)
	
	GlobalSave.MarkGameSaveLoaded()
	GlobalSave.SyncSave()
	return true


func _ResetRunStateForCoreReset() -> void:
	var clean_save: Dictionary = GlobalSave.BuildCleanSaveData()

	# KEEP META / PERSISTENT
	var keep_relic_inv: Dictionary = GlobalSave.save_data.get("relic_inv", {}).duplicate(true)
	var keep_skill_tree: Dictionary = GlobalSave.save_data.get("skill_tree", {}).duplicate(true)
	var keep_reward_chests: Dictionary = GlobalSave.save_data.get("reward_chests", {}).duplicate(true)
	var keep_milestones: Dictionary = GlobalSave.save_data.get("milestones", {}).duplicate(true)
	var keep_boss_progress: Dictionary = GlobalSave.save_data.get("boss_progress", {}).duplicate(true)
	var keep_daily_quests: Dictionary = GlobalSave.save_data.get("daily_quests", {}).duplicate(true)
	var keep_daily_free_bot: Dictionary = GlobalSave.save_data.get("daily_free_bot", {}).duplicate(true)
	var keep_settings: Dictionary = GlobalSave.save_data.get("settings", {}).duplicate(true)
	var keep_player_stats: Dictionary = GlobalSave.save_data.get("player_stats", {}).duplicate(true)
	var keep_meta: Dictionary = GlobalSave.save_data.get("meta", {}).duplicate(true)

	# RESET CURRENT RUN
	_ResetCurrenciesForCoreReset(clean_save)
	_ResetBotInventoryForCoreReset(clean_save)
	_ResetLanesForCoreReset(clean_save)
	_ResetProgressForCoreReset(clean_save)
	_ResetUpgradesForCoreReset(clean_save)
	_ResetTimedBonusesForCoreReset()
	_ResetLegacyGlobalUpgradesForCoreReset(clean_save)

	# RESTORE PERSISTENT / META
	GlobalSave.save_data["relic_inv"] = keep_relic_inv
	GlobalSave.save_data["skill_tree"] = keep_skill_tree
	GlobalSave.save_data["reward_chests"] = keep_reward_chests
	GlobalSave.save_data["milestones"] = keep_milestones
	GlobalSave.save_data["boss_progress"] = keep_boss_progress
	GlobalSave.save_data["daily_quests"] = keep_daily_quests
	GlobalSave.save_data["daily_free_bot"] = keep_daily_free_bot
	GlobalSave.save_data["settings"] = keep_settings

	# keep long-term player stats, but reset only the current prestige counter to the newly reached value
	GlobalSave.save_data["player_stats"] = keep_player_stats
	if !GlobalSave.save_data.player_stats.has("core_resets"):
		GlobalSave.save_data.player_stats["core_resets"] = 0
	if !GlobalSave.save_data.player_stats.has("current_prestige"):
		GlobalSave.save_data.player_stats["current_prestige"] = 0
	GlobalSave.save_data.player_stats["current_prestige"] = int(GlobalSave.save_data.player_stats.get("core_resets", 0))

	# keep save metadata / uid serial so no weird collisions
	GlobalSave.save_data["meta"] = keep_meta


func _ResetCurrenciesForCoreReset(clean_save: Dictionary = {}) -> void:
	var reset_currencies: Dictionary = {}

	# Keep all clean/default currency keys.
	var clean_currencies = clean_save.get("currencies", {})
	if typeof(clean_currencies) == TYPE_DICTIONARY:
		for currency_id in clean_currencies.keys():
			reset_currencies[str(currency_id)] = 0

	# Also reset any newer/dynamic currencies that exist in the current save.
	var current_currencies = GlobalSave.save_data.get("currencies", {})
	if typeof(current_currencies) == TYPE_DICTIONARY:
		for currency_id in current_currencies.keys():
			reset_currencies[str(currency_id)] = 0

	# Fallback safety.
	if reset_currencies.is_empty():
		reset_currencies = {
			"coins": 0,
			"crystals": 0,
			"energy": 0
		}

	GlobalSave.save_data["currencies"] = reset_currencies
	


func _ResetBotInventoryForCoreReset(clean_save: Dictionary) -> void:
	var clean_bot_inventory: Dictionary = clean_save.get("bot_inventory", {
		"bot_db": [],
		"merge_free_slots": 4
	}).duplicate(true)

	var strongest_bot := _GetStrongestBotToKeepForCoreReset()

	clean_bot_inventory["bot_db"] = []

	if !strongest_bot.is_empty():
		# make sure the kept bot starts clean in inventory
		strongest_bot["merge_slot_id"] = 0
		clean_bot_inventory["bot_db"].append(strongest_bot)

	GlobalSave.save_data["bot_inventory"] = clean_bot_inventory

func _GetStrongestBotToKeepForCoreReset() -> Dictionary:
	var bot_inventory = GlobalSave.save_data.get("bot_inventory", {})
	if typeof(bot_inventory) != TYPE_DICTIONARY:
		return {}

	var bot_db = bot_inventory.get("bot_db", [])
	if typeof(bot_db) != TYPE_ARRAY or bot_db.is_empty():
		return {}

	var best_bot: Dictionary = {}
	var best_level := -1
	var best_rank := -1
	var best_stat_score := -1.0
	var best_uid := 999999999

	for raw_bot in bot_db:
		if typeof(raw_bot) != TYPE_DICTIONARY:
			continue

		var bot: Dictionary = raw_bot
		var level := int(bot.get("level", 1))
		var rank := int(bot.get("rank", 0))
		var stat_score := _GetCoreResetBotTieBreakerScore(bot)
		var uid := int(bot.get("uid", 999999999))

		var should_take := false

		if best_bot.is_empty():
			should_take = true
		elif level > best_level:
			should_take = true
		elif level == best_level and rank > best_rank:
			should_take = true
		elif level == best_level and rank == best_rank and stat_score > best_stat_score:
			should_take = true
		elif level == best_level and rank == best_rank and is_equal_approx(stat_score, best_stat_score) and uid < best_uid:
			should_take = true

		if should_take:
			best_bot = bot.duplicate(true)
			best_level = level
			best_rank = rank
			best_stat_score = stat_score
			best_uid = uid

	return best_bot

func _GetCoreResetBotTieBreakerScore(bot_data: Dictionary) -> float:
	var stats = bot_data.get("stats", {})
	if typeof(stats) != TYPE_DICTIONARY:
		return 0.0

	var total := 0.0

	for stat_id in stats.keys():
		var stat_value = stats[stat_id]

		if typeof(stat_value) == TYPE_DICTIONARY:
			total += absf(float(stat_value.get("value", 0.0)))
		else:
			total += absf(float(stat_value))

	return total
	
func _ResetLanesForCoreReset(clean_save: Dictionary) -> void:
	var clean_lanes: Array = clean_save.get("lanes", []).duplicate(true)

	# fallback in case clean save changes unexpectedly
	if clean_lanes.is_empty():
		clean_lanes = []
		for lane_index in range(5):
			clean_lanes.append({
				"auto_dig_unlocked": lane_index == 0,
				"bot_uid": -1,
				"dig_power": 1.0,
				"dig_speed": 1.0,
				"lane_index": lane_index,
				"block_data": [],
				"lane_depth": 0,
				"last_cleared_depth": -1
			})

	for lane_data in clean_lanes:
		lane_data["bot_uid"] = -1
		lane_data["dig_power"] = 1.0
		lane_data["dig_speed"] = 1.0
		lane_data["lane_depth"] = 0
		lane_data["last_cleared_depth"] = -1
		lane_data["block_data"] = []

	GlobalSave.save_data["lanes"] = clean_lanes


func _ResetProgressForCoreReset(clean_save: Dictionary) -> void:
	var clean_progress: Dictionary = clean_save.get("progress", {
		"efficiency_mult": 1.0,
		"global_depth": 0
	}).duplicate(true)

	clean_progress["global_depth"] = 0
	clean_progress["efficiency_mult"] = 1.0
	clean_progress["total_bots_bought_this_reset"] = 0

	GlobalSave.save_data["progress"] = clean_progress


func _ResetUpgradesForCoreReset(clean_save: Dictionary) -> void:
	# safest version: reload the upgrade database fresh
	if GlobalSave.has_method("LoadUpgrades"):
		GlobalSave.save_data["upgrades"] = GlobalSave.LoadUpgrades().duplicate(true)
	else:
		GlobalSave.save_data["upgrades"] = clean_save.get("upgrades", {}).duplicate(true)


func _ResetLegacyGlobalUpgradesForCoreReset(clean_save: Dictionary) -> void:
	if clean_save.has("global_upgrades"):
		GlobalSave.save_data["global_upgrades"] = clean_save.get("global_upgrades", {}).duplicate(true)
	else:
		GlobalSave.save_data["global_upgrades"] = {
			"global_dig_power_level": 0,
			"global_dig_speed_level": 0,
			"offline_gain_level": 0.0
		}


func _ResetTimedBonusesForCoreReset() -> void:
	if !GlobalSave.save_data.has("timed_bonuses") or typeof(GlobalSave.save_data.timed_bonuses) != TYPE_DICTIONARY:
		GlobalSave.save_data["timed_bonuses"] = {
			"active": {},
			"daily_day_key": "",
			"daily_ids": []
		}
		return

	# clear only active temporary buffs
	GlobalSave.save_data.timed_bonuses["active"] = {}

	# keep the same day offer pool
	if !GlobalSave.save_data.timed_bonuses.has("daily_day_key"):
		GlobalSave.save_data.timed_bonuses["daily_day_key"] = ""
	if !GlobalSave.save_data.timed_bonuses.has("daily_ids") or typeof(GlobalSave.save_data.timed_bonuses.daily_ids) != TYPE_ARRAY:
		GlobalSave.save_data.timed_bonuses["daily_ids"] = []
