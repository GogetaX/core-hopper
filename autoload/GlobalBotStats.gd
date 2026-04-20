extends Node

const BOT_STATS_PATH := "res://data/bot_data/bot_aditional_stats.json"

const DEFAULT_RANK_TITLES := {
	0: "Rusted",
	1: "Refined",
	2: "Elite",
	3: "Mythic"
}

var bot_rank_data: Dictionary = {}

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
		copy["description"] = str(copy.get("description", ""))
		copy["icon"] = str(copy.get("icon", ""))
		copy["stat_type"] = str(copy.get("stat_type", "percent"))
		copy["weight"] = int(copy.get("weight", 0))
		copy["min_value"] = float(copy.get("min_value", 0.0))
		copy["max_value"] = float(copy.get("max_value", copy["min_value"]))
		copy["decimals"] = int(copy.get("decimals", 2))

		bot_stats_db[str(stat_id)] = copy

	var rules_data = data.get("bot_stat_roll_rules", {})
	if typeof(rules_data) == TYPE_DICTIONARY:
		bot_stat_roll_rules = rules_data.duplicate(true)
	
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
			bot_rank_data[rank] = copy
		
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


func RollBotStats(level: int = 1) -> Dictionary:
	if bot_stats_db.is_empty():
		LoadBotStats()

	if bot_stats_db.is_empty():
		return {
			"rank": 0,
			"stats": {}
		}

	level = maxi(1, level)

	var stats := {}
	var roll_count := _RollStatCount()

	if roll_count <= 0:
		return {
			"rank": 0,
			"stats": {}
		}

	var used_ids: Array[String] = []
	var highest_rank := 0

	for i in range(roll_count):
		var stat_id := _RollWeightedStatId(used_ids)
		if stat_id == "":
			break

		var stat_data: Dictionary = bot_stats_db.get(stat_id, {})
		if stat_data.is_empty():
			continue

		var rolled := _RollSingleStatValue(stat_id, stat_data, level)
		if rolled.is_empty():
			continue

		stats[stat_id] = float(rolled.get("value", 0.0))
		highest_rank = maxi(highest_rank, int(rolled.get("rank", 0)))
		used_ids.append(stat_id)

	return {
		"rank": highest_rank,
		"stats": stats
	}


func _RollSingleStatValue(stat_id: String, stat_data: Dictionary, level: int) -> Dictionary:
	var stat_type := str(stat_data.get("stat_type", "percent"))
	var min_value := float(stat_data.get("min_value", 0.0))
	var max_value := float(stat_data.get("max_value", min_value))

	if max_value < min_value:
		var tmp := min_value
		min_value = max_value
		max_value = tmp

	var rolled_source := _rng.randf_range(min_value, max_value)
	var final_value := rolled_source

	if stat_type == "flat":
		final_value = _ConvertFlatRollToLevelScaledValue(stat_id, rolled_source, level)
		var min_final := _ConvertFlatRollToLevelScaledValue(stat_id, min_value, level)
		var max_final := _ConvertFlatRollToLevelScaledValue(stat_id, max_value, level)

		var rank_spike_flat := _CalcSpike01(final_value, min_final, max_final)
		var rank_flat := _GetRankFromSpike01(rank_spike_flat)

		final_value = _SnapStatValue(final_value, int(stat_data.get("decimals", 2)))
		return {
			"value": final_value,
			"rank": rank_flat
		}

	var rank_spike := _CalcSpike01(rolled_source, min_value, max_value)
	var rank := _GetRankFromSpike01(rank_spike)

	final_value = _SnapStatValue(final_value, int(stat_data.get("decimals", 2)))
	return {
		"value": final_value,
		"rank": rank
	}


func _ConvertFlatRollToLevelScaledValue(stat_id: String, rolled_value: float, level: int) -> float:
	level = maxi(1, level)

	match stat_id:
		"dig_power":
			return _GetLevelCurveDeltaInt(level, rolled_value, "power")
		"dig_speed":
			return _GetLevelCurveDeltaFloat(level, rolled_value, "speed")
		_:
			return rolled_value


func _GetLevelCurveDeltaInt(base_level: int, bonus_levels: float, mode: String) -> float:
	bonus_levels = maxf(0.0, bonus_levels)

	var low_bonus := int(floor(bonus_levels))
	var high_bonus := int(ceil(bonus_levels))

	var low_value := 0.0
	var high_value := 0.0

	match mode:
		"power":
			low_value = float(GlobalStats.GetBotBaseDigPower(base_level + low_bonus) - GlobalStats.GetBotBaseDigPower(base_level))
			high_value = float(GlobalStats.GetBotBaseDigPower(base_level + high_bonus) - GlobalStats.GetBotBaseDigPower(base_level))
		_:
			return bonus_levels

	if high_bonus == low_bonus:
		return low_value

	var t := bonus_levels - float(low_bonus)
	return lerpf(low_value, high_value, t)


func _GetLevelCurveDeltaFloat(base_level: int, bonus_levels: float, mode: String) -> float:
	bonus_levels = maxf(0.0, bonus_levels)

	var low_bonus := int(floor(bonus_levels))
	var high_bonus := int(ceil(bonus_levels))

	var low_value := 0.0
	var high_value := 0.0

	match mode:
		"speed":
			low_value = float(GlobalStats.GetBotBaseDigSpeed(base_level + low_bonus) - GlobalStats.GetBotBaseDigSpeed(base_level))
			high_value = float(GlobalStats.GetBotBaseDigSpeed(base_level + high_bonus) - GlobalStats.GetBotBaseDigSpeed(base_level))
		_:
			return bonus_levels

	if high_bonus == low_bonus:
		return low_value

	var t := bonus_levels - float(low_bonus)
	return lerpf(low_value, high_value, t)


func _SnapStatValue(value: float, decimals: int) -> float:
	if decimals <= 0:
		return roundf(value)

	var step := pow(0.1, decimals)
	return snappedf(value, step)


func _CalcSpike01(value: float, min_value: float, max_value: float) -> float:
	if is_equal_approx(min_value, max_value):
		return 0.0
	return clampf(inverse_lerp(min_value, max_value, value), 0.0, 1.0)


func _GetRankFromSpike01(spike01: float) -> int:
	var t := clampf(spike01, 0.0, 1.0)

	if t >= 0.93:
		return 3 # Mythic
	if t >= 0.75:
		return 2 # Elite
	if t >= 0.50:
		return 1 # Refined
	return 0 # Rusted


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

func GetRankTitle(rank: int) -> String:
	var data := GetRankData(rank)
	if !data.is_empty():
		return str(data.get("title", DEFAULT_RANK_TITLES.get(rank, "Rusted")))
	return str(DEFAULT_RANK_TITLES.get(rank, "Rusted"))
	
func GetBotRankTitle(bot_data: Dictionary) -> String:
	if !HasAdditionalStats(bot_data):
		return ""
	return GetRankTitle(GetBotRank(bot_data))

func GetRankData(rank: int) -> Dictionary:
	if bot_rank_data.has(rank):
		return bot_rank_data[rank].duplicate(true)
	return {}



func GetBotRank(bot_data: Dictionary) -> int:
	if typeof(bot_data) != TYPE_DICTIONARY:
		return 0
	return int(bot_data.get("rank", 0))


func HasAdditionalStats(bot_data: Dictionary) -> bool:
	if typeof(bot_data) != TYPE_DICTIONARY:
		return false

	var stats = bot_data.get("stats", {})
	return typeof(stats) == TYPE_DICTIONARY and !stats.is_empty()

func GetStatDescription(stat_id: String, value: float) -> String:
	var stat_data := GetStatData(stat_id)
	if stat_data.is_empty():
		return str(value)

	var stat_type := str(stat_data.get("stat_type", "percent"))
	var decimals := int(stat_data.get("decimals", 0))

	match stat_type:
		"percent":
			var percent_value := value * 100.0
			return _FormatSignedNumber(percent_value, 0) + "%"

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

func RollBotStatsByRank(target_rank: int, level: int = 1, max_attempts: int = 24) -> Dictionary:
	if bot_stats_db.is_empty():
		LoadBotStats()

	if bot_stats_db.is_empty():
		return {
			"rank": 0,
			"stats": {}
		}

	target_rank = clampi(target_rank, 0, 3)
	level = maxi(1, level)
	max_attempts = maxi(1, max_attempts)

	var fallback := {
		"rank": 0,
		"stats": {}
	}

	for i in range(max_attempts):
		var rolled := _RollBotStatsByRankAttempt(target_rank, level)
		fallback = rolled
		if int(rolled.get("rank", 0)) == target_rank:
			return rolled

	return fallback


func _RollBotStatsByRankAttempt(target_rank: int, level: int) -> Dictionary:
	var stats := {}
	var roll_count := _RollStatCount()

	if roll_count <= 0:
		return {
			"rank": 0,
			"stats": {}
		}

	var used_ids: Array[String] = []
	var highest_rank := 0

	# For ranks above 0, force one stat to land in the target rank band.
	# For Rusted (0), all stats just need to stay <= 0.
	var forced_index := -1
	if target_rank > 0:
		forced_index = _rng.randi_range(0, roll_count - 1)

	for i in range(roll_count):
		var stat_id := _RollWeightedStatId(used_ids)
		if stat_id == "":
			break

		var stat_data: Dictionary = bot_stats_db.get(stat_id, {})
		if stat_data.is_empty():
			continue

		var rolled := {}

		if i == forced_index:
			rolled = _RollSingleStatValueForExactRank(stat_id, stat_data, level, target_rank)
		else:
			rolled = _RollSingleStatValueUpToRank(stat_id, stat_data, level, target_rank)

		if rolled.is_empty():
			continue

		stats[stat_id] = float(rolled.get("value", 0.0))
		highest_rank = maxi(highest_rank, int(rolled.get("rank", 0)))
		used_ids.append(stat_id)

	return {
		"rank": highest_rank,
		"stats": stats
	}


func _RollSingleStatValueUpToRank(stat_id: String, stat_data: Dictionary, level: int, max_rank: int, max_attempts: int = 12) -> Dictionary:
	max_rank = clampi(max_rank, 0, 3)
	max_attempts = maxi(1, max_attempts)

	var fallback := {}

	for i in range(max_attempts):
		var rolled := _RollSingleStatValue(stat_id, stat_data, level)
		if rolled.is_empty():
			continue

		fallback = rolled
		if int(rolled.get("rank", 0)) <= max_rank:
			return rolled

	return fallback


func _RollSingleStatValueForExactRank(stat_id: String, stat_data: Dictionary, level: int, target_rank: int) -> Dictionary:
	target_rank = clampi(target_rank, 0, 3)

	var stat_type := str(stat_data.get("stat_type", "percent"))
	var min_value := float(stat_data.get("min_value", 0.0))
	var max_value := float(stat_data.get("max_value", min_value))

	if max_value < min_value:
		var tmp := min_value
		min_value = max_value
		max_value = tmp

	var rank_range := _GetRankSpikeRange(target_rank)
	var spike_t := _rng.randf_range(rank_range.x, rank_range.y)

	var rolled_source := min_value
	if !is_equal_approx(min_value, max_value):
		rolled_source = lerpf(min_value, max_value, spike_t)

	var final_value := rolled_source
	var final_rank := target_rank

	if stat_type == "flat":
		final_value = _ConvertFlatRollToLevelScaledValue(stat_id, rolled_source, level)

		var min_final := _ConvertFlatRollToLevelScaledValue(stat_id, min_value, level)
		var max_final := _ConvertFlatRollToLevelScaledValue(stat_id, max_value, level)
		var rank_spike := _CalcSpike01(final_value, min_final, max_final)
		final_rank = _GetRankFromSpike01(rank_spike)
	else:
		var rank_spike := _CalcSpike01(rolled_source, min_value, max_value)
		final_rank = _GetRankFromSpike01(rank_spike)

	final_value = _SnapStatValue(final_value, int(stat_data.get("decimals", 2)))

	return {
		"value": final_value,
		"rank": final_rank
	}


func _GetRankSpikeRange(rank: int) -> Vector2:
	match clampi(rank, 0, 3):
		0:
			return Vector2(0.0, 0.4999)
		1:
			return Vector2(0.50, 0.7499)
		2:
			return Vector2(0.75, 0.9299)
		3:
			return Vector2(0.93, 1.0)
		_:
			return Vector2(0.0, 0.4999)
