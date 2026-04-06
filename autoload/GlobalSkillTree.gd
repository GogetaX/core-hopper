extends Node

signal skill_tree_loaded(tree_id: String)
signal skill_acquired(skill_id: String, new_level: int)

const SKILL_TREE_PATH := "res://data/skill_tree/skill_tree.json"

var _skill_tree_data: Dictionary = {}
var _skill_nodes: Dictionary = {}

var skill_summary = {}

func _ready() -> void:
	LoadSkillTree()
	UpdateSkillSummary("")
	GlobalSignals.OnSkillLevelUpdated.connect(UpdateSkillSummary)

func UpdateSkillSummary(_skill_id:String):
	skill_summary = BuildAcquiredSkillSummary()

func LoadSkillTree() -> void:
	_skill_tree_data.clear()
	_skill_nodes.clear()

	if !FileAccess.file_exists(SKILL_TREE_PATH):
		push_error("GlobalSkillTree: missing file: " + SKILL_TREE_PATH)
		return

	var json_text := FileAccess.get_file_as_string(SKILL_TREE_PATH)
	if json_text.strip_edges() == "":
		push_error("GlobalSkillTree: empty json file: " + SKILL_TREE_PATH)
		return

	var parsed = JSON.parse_string(json_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("GlobalSkillTree: invalid json root in: " + SKILL_TREE_PATH)
		return

	_skill_tree_data = parsed.duplicate(true)

	var nodes = _skill_tree_data.get("nodes", {})
	if typeof(nodes) != TYPE_DICTIONARY:
		push_error("GlobalSkillTree: 'nodes' must be a dictionary")
		return

	_skill_nodes = nodes.duplicate(true)

	_EnsureSkillTreeSaveData()

	var tree_id := str(_skill_tree_data.get("tree_id", ""))
	emit_signal("skill_tree_loaded", tree_id)


func ReloadSkillTree() -> void:
	LoadSkillTree()


func HasSkillTreeData() -> bool:
	return !_skill_tree_data.is_empty()


func GetSkillTreeData() -> Dictionary:
	return _skill_tree_data


func GetAllSkillNodes() -> Dictionary:
	return _skill_nodes


func GetTreeID() -> String:
	return str(_skill_tree_data.get("tree_id", ""))


func GetTreeCurrencyType() -> String:
	return str(_skill_tree_data.get("currency_type", "crystals"))


func GetStartNodeID() -> String:
	return str(_skill_tree_data.get("start_node_id", ""))


func HasSkill(skill_id: String) -> bool:
	_EnsureLoaded()

	var id := skill_id.strip_edges()
	if id == "":
		return false

	return _skill_nodes.has(id)


func GetSkillData(skill_id: String) -> Dictionary:
	_EnsureLoaded()

	var id := skill_id.strip_edges()
	if id == "":
		return {}

	if !_skill_nodes.has(id):
		return {}

	var data = _skill_nodes.get(id, {})
	if typeof(data) != TYPE_DICTIONARY:
		return {}

	return data


func GetSkillTitle(skill_id: String) -> String:
	var skill_data := GetSkillData(skill_id)
	return str(skill_data.get("title", ""))


func GetSkillBranch(skill_id: String) -> String:
	var skill_data := GetSkillData(skill_id)
	return str(skill_data.get("branch", ""))


func GetSkillMaxLevel(skill_id: String) -> int:
	var skill_data := GetSkillData(skill_id)
	return int(skill_data.get("max_level", 0))


func GetAcquiredSkillLevel(skill_id: String) -> int:
	_EnsureSkillTreeSaveData()

	var id := skill_id.strip_edges()
	if id == "":
		return 0

	var skill_tree = GlobalSave.save_data.get("skill_tree", {})
	if typeof(skill_tree) != TYPE_DICTIONARY:
		return 0

	var node_levels = skill_tree.get("node_levels", {})
	if typeof(node_levels) != TYPE_DICTIONARY:
		return 0

	return int(node_levels.get(id, 0))


func GetAccuredSkillLevel(skill_id: String) -> int:
	return GetAcquiredSkillLevel(skill_id)


func IsSkillAcquired(skill_id: String) -> bool:
	return GetAcquiredSkillLevel(skill_id) > 0


func IsSkillMaxed(skill_id: String) -> bool:
	var max_level := GetSkillMaxLevel(skill_id)
	if max_level <= 0:
		return false

	return GetAcquiredSkillLevel(skill_id) >= max_level


func GetSkillNextCost(skill_id: String) -> int:
	var skill_data := GetSkillData(skill_id)
	if skill_data.is_empty():
		return -1

	var current_level := GetAcquiredSkillLevel(skill_id)
	var max_level := int(skill_data.get("max_level", 0))
	if current_level >= max_level:
		return -1

	var costs = skill_data.get("costs", [])
	if typeof(costs) != TYPE_ARRAY:
		return -1

	if current_level < 0 or current_level >= costs.size():
		return -1

	return int(costs[current_level])


func GetSkillPrereqIDs(skill_id: String) -> Array:
	var skill_data := GetSkillData(skill_id)
	if skill_data.is_empty():
		return []

	var prereq_ids = skill_data.get("prereq_ids", [])
	if typeof(prereq_ids) != TYPE_ARRAY:
		return []

	return prereq_ids.duplicate()


func AreSkillPrereqsMet(skill_id: String) -> bool:
	var skill_data := GetSkillData(skill_id)
	if skill_data.is_empty():
		return false

	var prereq_ids = skill_data.get("prereq_ids", [])
	if typeof(prereq_ids) != TYPE_ARRAY:
		return true

	for prereq_id in prereq_ids:
		if GetAcquiredSkillLevel(str(prereq_id)) <= 0:
			return false

	return true


func CanAcquireSkill(skill_id: String) -> bool:
	var skill_data := GetSkillData(skill_id)
	if skill_data.is_empty():
		return false

	var current_level := GetAcquiredSkillLevel(skill_id)
	var max_level := int(skill_data.get("max_level", 0))
	if current_level >= max_level:
		return false

	if !AreSkillPrereqsMet(skill_id):
		return false

	var next_cost := GetSkillNextCost(skill_id)
	if next_cost < 0:
		return false

	var currency_type := GetTreeCurrencyType()
	if GetCurrencyAmount(currency_type) < next_cost:
		return false

	return true


func AcquireSkill(skill_id: String) -> bool:
	_EnsureLoaded()
	_EnsureSkillTreeSaveData()

	var id := skill_id.strip_edges()
	if id == "":
		return false

	if !CanAcquireSkill(id):
		return false

	var next_cost := GetSkillNextCost(id)
	var currency_type := GetTreeCurrencyType()

	if !_SpendCurrency(currency_type, next_cost):
		return false

	var skill_tree: Dictionary = GlobalSave.save_data.get("skill_tree", {})
	var node_levels: Dictionary = skill_tree.get("node_levels", {})

	var current_level := int(node_levels.get(id, 0))
	current_level += 1
	node_levels[id] = current_level

	skill_tree["node_levels"] = node_levels
	skill_tree["tree_id"] = GetTreeID()
	skill_tree["version"] = int(_skill_tree_data.get("version", 1))
	GlobalSave.save_data["skill_tree"] = skill_tree

	_RequestSave()

	emit_signal("skill_acquired", id, current_level)
	return true


func AccureSkill(skill_id: String) -> bool:
	return AcquireSkill(skill_id)


func GetAllAcquiredSkillLevels() -> Dictionary:
	_EnsureSkillTreeSaveData()

	var skill_tree = GlobalSave.save_data.get("skill_tree", {})
	if typeof(skill_tree) != TYPE_DICTIONARY:
		return {}

	var node_levels = skill_tree.get("node_levels", {})
	if typeof(node_levels) != TYPE_DICTIONARY:
		return {}

	return node_levels.duplicate(true)


func GetAllAcquiredSkillIDs() -> Array:
	var node_levels := GetAllAcquiredSkillLevels()
	var result: Array = []

	for skill_id in node_levels.keys():
		if int(node_levels[skill_id]) > 0:
			result.append(skill_id)

	return result


func GetSkillEffects(skill_id: String) -> Array:
	var skill_data := GetSkillData(skill_id)
	if skill_data.is_empty():
		return []

	var effects = skill_data.get("effects", [])
	if typeof(effects) != TYPE_ARRAY:
		return []

	return effects.duplicate(true)


func GetTotalSkillStatValue(stat_name: String) -> float:
	_EnsureLoaded()
	_EnsureSkillTreeSaveData()

	var total := 0.0
	var node_levels := GetAllAcquiredSkillLevels()

	for skill_id in node_levels.keys():
		var level := int(node_levels[skill_id])
		if level <= 0:
			continue

		var effects = GetSkillEffects(str(skill_id))
		for effect in effects:
			if typeof(effect) != TYPE_DICTIONARY:
				continue

			if str(effect.get("kind", "")) != "stat":
				continue

			if str(effect.get("stat", "")) != stat_name:
				continue

			var value_per_level := float(effect.get("value_per_level", 0.0))
			total += value_per_level * level

	return total


func HasUnlockFeature(feature_name: String, target_level: int = -1) -> bool:
	_EnsureLoaded()
	_EnsureSkillTreeSaveData()

	var node_levels := GetAllAcquiredSkillLevels()

	for skill_id in node_levels.keys():
		var level := int(node_levels[skill_id])
		if level <= 0:
			continue

		var effects = GetSkillEffects(str(skill_id))
		for effect in effects:
			if typeof(effect) != TYPE_DICTIONARY:
				continue

			if str(effect.get("kind", "")) != "unlock":
				continue

			if str(effect.get("feature", "")) != feature_name:
				continue

			if target_level == -1:
				return true

			if int(effect.get("level", -1)) == target_level:
				return true

	return false


func _EnsureLoaded() -> void:
	if _skill_tree_data.is_empty():
		LoadSkillTree()


func _EnsureSkillTreeSaveData() -> void:
	if typeof(GlobalSave.save_data) != TYPE_DICTIONARY:
		GlobalSave.save_data = {}

	var skill_tree = GlobalSave.save_data.get("skill_tree", {})
	if typeof(skill_tree) != TYPE_DICTIONARY:
		skill_tree = {}

	if !skill_tree.has("tree_id"):
		skill_tree["tree_id"] = GetTreeID()

	if !skill_tree.has("version"):
		skill_tree["version"] = int(_skill_tree_data.get("version", 1))

	var node_levels = skill_tree.get("node_levels", {})
	if typeof(node_levels) != TYPE_DICTIONARY:
		node_levels = {}

	skill_tree["node_levels"] = node_levels
	GlobalSave.save_data["skill_tree"] = skill_tree


func GetCurrencyAmount(currency_type: String) -> int:
	var key := currency_type.strip_edges()
	if key == "":
		return 0

	if GlobalSave.has_method("GetCurrency"):
		return int(GlobalSave.GetCurrency(key))

	return 0


func _SpendCurrency(currency_type: String, amount: int) -> bool:
	var key := currency_type.strip_edges()
	if key == "":
		return false

	if amount < 0:
		return false

	var current_amount := GetCurrencyAmount(key)
	if current_amount < amount:
		return false

	if GlobalSave.has_method("AddCurrency"):
		GlobalSave.AddCurrency(key, -amount)
		return true

	return false


func _RequestSave() -> void:
	if GlobalSave.has_method("SaveGame"):
		GlobalSave.SaveGame()
	elif GlobalSave.has_method("SaveData"):
		GlobalSave.SaveData()
	elif GlobalSave.has_method("WriteSave"):
		GlobalSave.WriteSave()

func GetIconFromStr(icon_str):
	return load("res://art/skills/"+icon_str+".tres")

func GetSkillEffectLine(skill_id: String, level: int = -1) -> String:
	var skill_data := GetSkillData(skill_id)
	if skill_data.is_empty():
		return ""

	var target_level := level
	if target_level < 0:
		target_level = GetAcquiredSkillLevel(skill_id)

	if target_level <= 0:
		target_level = 1

	var effects = skill_data.get("effects", [])
	if typeof(effects) != TYPE_ARRAY:
		return ""

	var parts: Array[String] = []

	for effect in effects:
		if typeof(effect) != TYPE_DICTIONARY:
			continue

		var text := _BuildEffectText(effect, target_level)
		if text != "":
			parts.append(text)

	return "\n".join(parts)


func GetSkillCurrentEffectLine(skill_id: String) -> String:
	return GetSkillEffectLine(skill_id, GetAcquiredSkillLevel(skill_id))


func GetSkillNextEffectLine(skill_id: String) -> String:
	var next_level := GetAcquiredSkillLevel(skill_id) + 1
	var max_level := GetSkillMaxLevel(skill_id)
	if max_level > 0:
		next_level = min(next_level, max_level)
	return GetSkillEffectLine(skill_id, next_level)


func _BuildEffectText(effect: Dictionary, level: int) -> String:
	var kind := str(effect.get("kind", ""))

	if kind == "stat":
		return _BuildStatEffectText(effect, level)

	if kind == "unlock":
		return _BuildUnlockEffectText(effect)

	return ""


func _BuildStatEffectText(effect: Dictionary, level: int) -> String:
	var stat := str(effect.get("stat", ""))
	var value_per_level := float(effect.get("value_per_level", 0.0))
	var total_value := value_per_level * level

	match stat:
		"merge_slot_bonus":
			return "+%d Merge Bot Slot" % int(total_value)

		"merge_output_power_mult":
			return "+%d%% Merge Output Power" % _ToPercentInt(total_value)

		"merge_refund_chance":
			return "+%d%% Merge Refund Chance" % _ToPercentInt(total_value)

		"boss_damage_mult":
			return "+%d%% Boss Damage" % _ToPercentInt(total_value)

		"boss_reward_mult":
			return "+%d%% Boss Rewards" % _ToPercentInt(total_value)

		"boss_relic_drop_chance":
			return "+%d%% Boss Relic Drop Chance" % _ToPercentInt(total_value)

		"boss_rare_relic_drop_chance":
			return "+%d%% Rare Relic Drop Chance" % _ToPercentInt(total_value)

		"boss_regen_reduction":
			return "-%d%% Boss Regen" % _ToPercentInt(total_value)

		"max_offline_seconds":
			return "+%s Offline Time" % _FormatSecondsShort(int(total_value))

		"offline_gain_mult":
			return "+%d%% Offline Gains" % _ToPercentInt(total_value)

		"offline_coin_gain_mult":
			return "+%d%% Offline Coin Gain" % _ToPercentInt(total_value)

		"offline_crystal_gain_mult":
			return "+%d%% Offline Crystal Gain" % _ToPercentInt(total_value)

		"offline_chest_queue_capacity":
			return "+%d Offline Chest Queue" % int(total_value)

		"direct_bot_buy_cost_reduction":
			return "-%d%% Direct Buy Cost" % _ToPercentInt(total_value)

		"bought_bot_power_mult":
			return "+%d%% Bought Bot Power" % _ToPercentInt(total_value)

		"tap_damage_mult":
			return "+%d%% Tap Damage" % _ToPercentInt(total_value)

		"tap_execute_threshold":
			return "+%d%% Execute Threshold" % _ToPercentInt(total_value)

		"tap_crit_chance":
			return "+%d%% Tap Crit Chance" % _ToPercentInt(total_value)

		"tap_crit_mult":
			return "+%d%% Tap Crit Multiplier" % _ToPercentInt(total_value)

		"tap_execute_reward_mult":
			return "+%d%% Execute Rewards" % _ToPercentInt(total_value)

		"front_block_tap_damage_mult":
			return "+%d%% Front Block Tap Damage" % _ToPercentInt(total_value)

	return ""


func _BuildUnlockEffectText(effect: Dictionary) -> String:
	var feature := str(effect.get("feature", ""))

	match feature:
		"direct_bot_buy_level":
			return "Can Buy Level %d Bots" % int(effect.get("level", 0))

		"tap_execute":
			var threshold := float(effect.get("threshold", 0.0))
			return "Unlock Tap Execute at %d%% HP" % _ToPercentInt(threshold)

	return ""


func _ToPercentInt(value: float) -> int:
	return int(round(value * 100.0))


func _FormatSecondsShort(seconds: int) -> String:
	if seconds <= 0:
		return "0m"

	var total_minutes := int(round(seconds / 60.0))
	var hours = total_minutes / 60.0
	var minutes = total_minutes % 60

	if hours > 0 and minutes > 0:
		return "%dh %dm" % [hours, minutes]
	if hours > 0:
		return "%dh" % hours
	return "%dm" % minutes

func BuildAcquiredSkillSummary() -> Dictionary:
	_EnsureLoaded()
	_EnsureSkillTreeSaveData()

	var summary: Dictionary = {
		"stats": {},
		"unlock_features": {},
		"node_levels": GetAllAcquiredSkillLevels(),
		"acquired_skill_ids": GetAllAcquiredSkillIDs()
	}

	_InitSkillSummaryDefaults(summary)

	var node_levels: Dictionary = summary.get("node_levels", {})
	for skill_id in node_levels.keys():
		var level := int(node_levels.get(skill_id, 0))
		if level <= 0:
			continue

		var effects = GetSkillEffects(str(skill_id))
		if typeof(effects) != TYPE_ARRAY:
			continue

		for effect in effects:
			if typeof(effect) != TYPE_DICTIONARY:
				continue

			var kind := str(effect.get("kind", ""))
			match kind:
				"stat":
					_ApplyStatEffectToSummary(summary, effect, level)
				"unlock":
					_ApplyUnlockEffectToSummary(summary, effect)

	_FinalizeSkillSummary(summary)
	return summary
	
func _ApplyStatEffectToSummary(summary: Dictionary, effect: Dictionary, level: int) -> void:
	var stats: Dictionary = summary.get("stats", {})

	var stat_name := str(effect.get("stat", ""))
	if stat_name == "":
		return

	var value_per_level := float(effect.get("value_per_level", 0.0))
	var add_value := value_per_level * level

	if !stats.has(stat_name):
		stats[stat_name] = 0.0

	stats[stat_name] = float(stats.get(stat_name, 0.0)) + add_value
	summary["stats"] = stats
	
func _InitSkillSummaryDefaults(summary: Dictionary) -> void:
	var stats: Dictionary = summary.get("stats", {})
	var unlock_features: Dictionary = summary.get("unlock_features", {})

	for skill_id in _skill_nodes.keys():
		var skill_data = _skill_nodes.get(skill_id, {})
		if typeof(skill_data) != TYPE_DICTIONARY:
			continue

		var effects = skill_data.get("effects", [])
		if typeof(effects) != TYPE_ARRAY:
			continue

		for effect in effects:
			if typeof(effect) != TYPE_DICTIONARY:
				continue

			var kind := str(effect.get("kind", ""))

			if kind == "stat":
				var stat_name := str(effect.get("stat", ""))
				if stat_name != "" and !stats.has(stat_name):
					stats[stat_name] = 0.0

			elif kind == "unlock":
				var feature := str(effect.get("feature", ""))
				if feature == "":
					continue

				match feature:
					"direct_bot_buy_level":
						if !unlock_features.has(feature):
							unlock_features[feature] = {
								"unlocked": false,
								"max_level": 0,
								"unlocked_levels": [],
								"cost_multiplier_by_level": {}
							}

						var feature_data: Dictionary = unlock_features[feature]
						var buy_level := int(effect.get("level", 0))
						var base_cost_multiplier := float(effect.get("base_cost_multiplier", 0.0))
						if buy_level > 0:
							feature_data["cost_multiplier_by_level"][str(buy_level)] = base_cost_multiplier
						unlock_features[feature] = feature_data

					"tap_execute":
						if !unlock_features.has(feature):
							unlock_features[feature] = {
								"unlocked": false,
								"target": str(effect.get("target", "")),
								"base_threshold": float(effect.get("threshold", 0.0)),
								"threshold_bonus": 0.0,
								"threshold_total": 0.0
							}
						else:
							var execute_data: Dictionary = unlock_features[feature]
							if str(execute_data.get("target", "")) == "":
								execute_data["target"] = str(effect.get("target", ""))
							if float(execute_data.get("base_threshold", 0.0)) <= 0.0:
								execute_data["base_threshold"] = float(effect.get("threshold", 0.0))
							unlock_features[feature] = execute_data

					_:
						if !unlock_features.has(feature):
							unlock_features[feature] = {
								"unlocked": false
							}

	summary["stats"] = stats
	summary["unlock_features"] = unlock_features
	
func _ApplyUnlockEffectToSummary(summary: Dictionary, effect: Dictionary) -> void:
	var unlock_features: Dictionary = summary.get("unlock_features", {})

	var feature := str(effect.get("feature", ""))
	if feature == "":
		return

	if !unlock_features.has(feature):
		unlock_features[feature] = {
			"unlocked": false
		}

	var feature_data: Dictionary = unlock_features[feature]
	feature_data["unlocked"] = true

	match feature:
		"direct_bot_buy_level":
			var buy_level := int(effect.get("level", 0))
			if buy_level > int(feature_data.get("max_level", 0)):
				feature_data["max_level"] = buy_level

			var unlocked_levels: Array = feature_data.get("unlocked_levels", [])
			if !unlocked_levels.has(buy_level):
				unlocked_levels.append(buy_level)
				unlocked_levels.sort()
			feature_data["unlocked_levels"] = unlocked_levels

			var cost_map: Dictionary = feature_data.get("cost_multiplier_by_level", {})
			cost_map[str(buy_level)] = float(effect.get("base_cost_multiplier", 0.0))
			feature_data["cost_multiplier_by_level"] = cost_map

		"tap_execute":
			feature_data["target"] = str(effect.get("target", feature_data.get("target", "")))
			feature_data["base_threshold"] = float(effect.get("threshold", feature_data.get("base_threshold", 0.0)))

	unlock_features[feature] = feature_data
	summary["unlock_features"] = unlock_features
	
func _FinalizeSkillSummary(summary: Dictionary) -> void:
	var stats: Dictionary = summary.get("stats", {})
	var unlock_features: Dictionary = summary.get("unlock_features", {})

	if unlock_features.has("tap_execute"):
		var execute_data: Dictionary = unlock_features.get("tap_execute", {})
		var bonus := float(stats.get("tap_execute_threshold", 0.0))
		execute_data["threshold_bonus"] = bonus

		if bool(execute_data.get("unlocked", false)):
			execute_data["threshold_total"] = float(execute_data.get("base_threshold", 0.0)) + bonus
		else:
			execute_data["threshold_total"] = 0.0

		unlock_features["tap_execute"] = execute_data

	summary["stats"] = stats
	summary["unlock_features"] = unlock_features
	
func BuildFlatAcquiredSkillStats() -> Dictionary:
	var summary := BuildAcquiredSkillSummary()
	var result: Dictionary = {}

	var stats: Dictionary = summary.get("stats", {})
	for stat_name in stats.keys():
		result[stat_name] = stats[stat_name]

	var unlock_features: Dictionary = summary.get("unlock_features", {})

	if unlock_features.has("direct_bot_buy_level"):
		var direct_buy: Dictionary = unlock_features["direct_bot_buy_level"]
		result["direct_bot_buy_level"] = int(direct_buy.get("max_level", 0))
		result["direct_bot_buy_unlocked_levels"] = direct_buy.get("unlocked_levels", []).duplicate()
		result["direct_bot_buy_cost_multiplier_by_level"] = direct_buy.get("cost_multiplier_by_level", {}).duplicate(true)
	else:
		result["direct_bot_buy_level"] = 0
		result["direct_bot_buy_unlocked_levels"] = []
		result["direct_bot_buy_cost_multiplier_by_level"] = {}

	if unlock_features.has("tap_execute"):
		var execute_data: Dictionary = unlock_features["tap_execute"]
		result["tap_execute_unlocked"] = bool(execute_data.get("unlocked", false))
		result["tap_execute_target"] = str(execute_data.get("target", ""))
		result["tap_execute_base_threshold"] = float(execute_data.get("base_threshold", 0.0))
		result["tap_execute_threshold_total"] = float(execute_data.get("threshold_total", 0.0))
	else:
		result["tap_execute_unlocked"] = false
		result["tap_execute_target"] = ""
		result["tap_execute_base_threshold"] = 0.0
		result["tap_execute_threshold_total"] = 0.0
	
	return result
