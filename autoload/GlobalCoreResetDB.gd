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
			var start_level := 1 + int(round(next_total))
			return "Start with Level " + str(start_level) + " Bots"

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
