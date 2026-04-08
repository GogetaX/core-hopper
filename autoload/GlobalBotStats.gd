extends Node

const BOT_STATS_PATH := "res://data/bot_data/bot_aditional_stats.json"

var bot_stats_db: Dictionary = {}
var bot_stat_roll_rules: Dictionary = {}

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	LoadBotStats()


func LoadBotStats(path: String = BOT_STATS_PATH) -> bool:
	bot_stats_db.clear()
	bot_stat_roll_rules.clear()

	if !FileAccess.file_exists(path):
		push_warning("LoadBotStats: file not found -> " + path)
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("LoadBotStats: failed to open -> " + path)
		return false

	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		push_warning("LoadBotStats: invalid json -> " + path)
		return false

	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("LoadBotStats: root must be Dictionary")
		return false

	var stats_data = data.get("bot_random_stats", {})
	if typeof(stats_data) != TYPE_DICTIONARY:
		push_warning("LoadBotStats: bot_random_stats missing")
		return false

	for stat_id in stats_data.keys():
		var stat_data = stats_data[stat_id]
		if typeof(stat_data) != TYPE_DICTIONARY:
			continue

		var copy = stat_data.duplicate(true)
		copy["id"] = str(stat_id)
		copy["title"] = str(copy.get("title", stat_id))
		copy["stat_type"] = str(copy.get("stat_type", "percent"))
		copy["weight"] = int(copy.get("weight", 0))
		copy["min_value"] = float(copy.get("min_value", 0.0))
		copy["max_value"] = float(copy.get("max_value", copy["min_value"]))

		bot_stats_db[str(stat_id)] = copy

	var rules_data = data.get("bot_stat_roll_rules", {})
	if typeof(rules_data) == TYPE_DICTIONARY:
		bot_stat_roll_rules = rules_data.duplicate(true)

	return !bot_stats_db.is_empty()


func ReloadData() -> bool:
	return LoadBotStats()


func GetStatData(stat_id: String) -> Dictionary:
	if bot_stats_db.has(stat_id):
		return bot_stats_db[stat_id].duplicate(true)
	return {}


func GetBotStatValue(bot_data: Dictionary, stat_id: String) -> float:
	if typeof(bot_data) != TYPE_DICTIONARY:
		return 0.0

	var stats = bot_data.get("stats", {})
	if typeof(stats) != TYPE_DICTIONARY:
		return 0.0

	return float(stats.get(stat_id, 0.0))


func BotStatMultiplier(bot_data: Dictionary, stat_id: String) -> float:
	var value := GetBotStatValue(bot_data, stat_id)
	var stat_data := GetStatData(stat_id)
	var stat_type := str(stat_data.get("stat_type", "percent"))

	match stat_type:
		"percent":
			return 1.0 + value
		"multiplier":
			return value
		"flat":
			return value
		_:
			return 1.0 + value


func RollBotStats() -> Dictionary:
	if bot_stats_db.is_empty():
		LoadBotStats()

	if bot_stats_db.is_empty():
		return {}

	var result := {}
	var roll_count := _RollStatCount()
	if roll_count <= 0:
		return result

	var used_ids: Array[String] = []

	for i in range(roll_count):
		var stat_id := _RollWeightedStatId(used_ids)
		if stat_id == "":
			break

		var stat_data = bot_stats_db.get(stat_id, {})
		if typeof(stat_data) != TYPE_DICTIONARY:
			continue

		var min_value := float(stat_data.get("min_value", 0.0))
		var max_value := float(stat_data.get("max_value", min_value))

		if max_value < min_value:
			var tmp := min_value
			min_value = max_value
			max_value = tmp

		var value := _rng.randf_range(min_value, max_value)
		value = snappedf(value, 0.01)

		result[stat_id] = value
		used_ids.append(stat_id)

	return result


func _RollStatCount() -> int:
	var count_weights = bot_stat_roll_rules.get("roll_count_weights", {})
	if typeof(count_weights) != TYPE_DICTIONARY or count_weights.is_empty():
		return 1

	var total_weight := 0
	for key in count_weights.keys():
		var w := int(count_weights[key])
		if w > 0:
			total_weight += w

	if total_weight <= 0:
		return 1

	var roll := _rng.randi_range(1, total_weight)
	var running := 0

	for key in count_weights.keys():
		var w := int(count_weights[key])
		if w <= 0:
			continue

		running += w
		if roll <= running:
			return max(0, int(str(key)))

	return 1


func _RollWeightedStatId(excluded_ids: Array[String] = []) -> String:
	var total_weight := 0

	for stat_id in bot_stats_db.keys():
		if excluded_ids.has(stat_id):
			continue

		var stat_data = bot_stats_db[stat_id]
		var weight := int(stat_data.get("weight", 0))
		if weight > 0:
			total_weight += weight

	if total_weight <= 0:
		return ""

	var roll := _rng.randi_range(1, total_weight)
	var running := 0

	for stat_id in bot_stats_db.keys():
		if excluded_ids.has(stat_id):
			continue

		var stat_data = bot_stats_db[stat_id]
		var weight := int(stat_data.get("weight", 0))
		if weight <= 0:
			continue

		running += weight
		if roll <= running:
			return stat_id

	return ""
