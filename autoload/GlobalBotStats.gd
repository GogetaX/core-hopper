extends Node

const BOT_STATS_PATH := "res://data/bot_data/bot_aditional_stats.json"

const DEFAULT_RANK_TITLES := {
	0: "Rusted",
	1: "Refined",
	2: "Elite",
	3: "Mythic"
}

var bot_stats_db: Dictionary = {}
var bot_rank_data: Dictionary = {}
var bot_stat_roll_rules: Dictionary = {}

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	LoadBotStats()


func LoadBotStats(path: String = BOT_STATS_PATH) -> bool:
	bot_stats_db.clear()
	bot_rank_data.clear()
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
		copy["decimals"] = int(copy.get("decimals", 2))

		bot_stats_db[str(stat_id)] = copy

	var rank_data = data.get("bot_rank_data", {})
	if typeof(rank_data) == TYPE_DICTIONARY:
		for rank_key in rank_data.keys():
			var rank_info = rank_data[rank_key]
			if typeof(rank_info) != TYPE_DICTIONARY:
				continue

			var rank := int(str(rank_key))
			var copy = rank_info.duplicate(true)
			copy["id"] = rank
			copy["title"] = str(copy.get("title", DEFAULT_RANK_TITLES.get(rank, "Rusted")))
			copy["weight"] = int(copy.get("weight", 0))
			copy["multiplier"] = float(copy.get("multiplier", 1.0))

			bot_rank_data[rank] = copy

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


func HasStatData(stat_id: String) -> bool:
	return bot_stats_db.has(stat_id)


func GetRankData(rank: int) -> Dictionary:
	if bot_rank_data.has(rank):
		return bot_rank_data[rank].duplicate(true)
	return {}


func GetRankTitle(rank: int) -> String:
	var data := GetRankData(rank)
	if !data.is_empty():
		return str(data.get("title", DEFAULT_RANK_TITLES.get(rank, "Rusted")))
	return str(DEFAULT_RANK_TITLES.get(rank, "Rusted"))


func GetRankMultiplier(rank: int) -> float:
	var data := GetRankData(rank)
	if !data.is_empty():
		return float(data.get("multiplier", 1.0))
	return 1.0


func GetBotRank(bot_data: Dictionary) -> int:
	if typeof(bot_data) != TYPE_DICTIONARY:
		return 0
	return int(bot_data.get("rank", 0))


func GetBotRankTitle(bot_data: Dictionary) -> String:
	if !HasAdditionalStats(bot_data):
		return ""
	return GetRankTitle(GetBotRank(bot_data))


func GetBotRankMultiplier(bot_data: Dictionary) -> float:
	return GetRankMultiplier(GetBotRank(bot_data))


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
		return {
			"rank": 0,
			"stats": {}
		}

	var stats := {}
	var roll_count := _RollStatCount()

	# no additional stats on this bot
	if roll_count <= 0:
		return {
			"rank": 0,
			"stats": {}
		}

	var rolled_rank := _RollRank()
	var rank_mult := GetRankMultiplier(rolled_rank)
	var used_ids: Array = []

	for i in range(roll_count):
		var stat_id := _RollWeightedStatId(used_ids)
		if stat_id == "":
			break

		var stat_data: Dictionary = bot_stats_db.get(stat_id, {})
		if stat_data.is_empty():
			continue

		var min_value := float(stat_data.get("min_value", 0.0))
		var max_value := float(stat_data.get("max_value", min_value))

		if max_value < min_value:
			var tmp := min_value
			min_value = max_value
			max_value = tmp

		var value := _rng.randf_range(min_value, max_value)
		value *= rank_mult
		value = _SnapStatValue(value, int(stat_data.get("decimals", 2)))

		stats[stat_id] = value
		used_ids.append(stat_id)

	return {
		"rank": rolled_rank,
		"stats": stats
	}

func _SnapStatValue(value: float, decimals: int) -> float:
	if decimals <= 0:
		return roundf(value)

	var step := pow(0.1, decimals)
	return snappedf(value, step)


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
			return maxi(0, int(str(key)))

	return 1


func _RollRank() -> int:
	if bot_rank_data.is_empty():
		return 0

	var total_weight := 0
	for rank in bot_rank_data.keys():
		var rank_info: Dictionary = bot_rank_data[rank]
		var weight := int(rank_info.get("weight", 0))
		if weight > 0:
			total_weight += weight

	if total_weight <= 0:
		return 0

	var roll := _rng.randi_range(1, total_weight)
	var running := 0

	for rank in bot_rank_data.keys():
		var rank_info: Dictionary = bot_rank_data[rank]
		var weight := int(rank_info.get("weight", 0))
		if weight <= 0:
			continue

		running += weight
		if roll <= running:
			return int(rank)

	return 0


func _RollWeightedStatId(excluded_ids: Array = []) -> String:
	var total_weight := 0

	for stat_id in bot_stats_db.keys():
		if excluded_ids.has(stat_id):
			continue

		var stat_data: Dictionary = bot_stats_db[stat_id]
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

		var stat_data: Dictionary = bot_stats_db[stat_id]
		var weight := int(stat_data.get("weight", 0))
		if weight <= 0:
			continue

		running += weight
		if roll <= running:
			return str(stat_id)

	return ""

func GetStatDescription(stat_id: String, value: float) -> String:
	var stat_data := GetStatData(stat_id)
	if stat_data.is_empty():
		return str(value)

	var stat_type := str(stat_data.get("stat_type", "percent"))
	var decimals := int(stat_data.get("decimals", 0))

	match stat_type:
		"percent":
			var percent_value := value * 100.0
			return _FormatSignedNumber(percent_value, decimals) + "%"

		"multiplier":
			return _FormatSignedNumber(value, decimals) + "x"

		"flat":
			return _FormatSignedNumber(value, decimals)

		_:
			var percent_value := value * 100.0
			return _FormatSignedNumber(percent_value, decimals) + "%"


func _FormatSignedNumber(value: float, decimals: int = 0) -> String:
	var sign_value := "+"
	if value < 0.0:
		sign_value = "-"

	var abs_value := absf(value)

	if decimals <= 0:
		return sign_value + str(int(round(abs_value)))

	return sign_value + ("%.*f" % [decimals, abs_value])

func GetIcon(icon_str):
	return load("res://data/icons/"+icon_str+".tres")

func HasAdditionalStats(bot_data: Dictionary) -> bool:
	if typeof(bot_data) != TYPE_DICTIONARY:
		return false

	var stats = bot_data.get("stats", {})
	return typeof(stats) == TYPE_DICTIONARY and !stats.is_empty()
	
