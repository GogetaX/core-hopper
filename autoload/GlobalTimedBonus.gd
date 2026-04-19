extends Node

const BONUS_DB_PATH := "res://data/bonus/bonus_database.json"
const SAVE_KEY := "timed_bonuses"
const DEFAULT_DAILY_RANDOM_COUNT := 3

var _bonus_db: Dictionary = {}
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	LoadBonusDatabase()
	_EnsureSaveSection()
	CleanupExpiredBoosters()


func LoadBonusDatabase() -> bool:
	_bonus_db.clear()

	if !FileAccess.file_exists(BONUS_DB_PATH):
		push_error("GlobalTimedBonus: Missing DB file: %s" % BONUS_DB_PATH)
		return false

	var f := FileAccess.open(BONUS_DB_PATH, FileAccess.READ)
	if f == null:
		push_error("GlobalTimedBonus: Failed to open DB file: %s" % BONUS_DB_PATH)
		return false

	var json_text := f.get_as_text()
	f.close()

	var json := JSON.new()
	var err := json.parse(json_text)
	if err != OK:
		push_error("GlobalTimedBonus: JSON parse error at line %d: %s" % [
			json.get_error_line(),
			json.get_error_message()
		])
		return false

	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("GlobalTimedBonus: DB root must be a Dictionary")
		return false

	_bonus_db = json.data
	return true


func GetBonusData() -> Dictionary:
	return _bonus_db.duplicate(true)


func GetDailyRandom(amount: int = DEFAULT_DAILY_RANDOM_COUNT) -> Array:
	_EnsureSaveSection()

	if _bonus_db.is_empty():
		LoadBonusDatabase()

	var section := _GetSaveSection()
	var today_key := _GetTodayKey()
	var saved_day_key := str(section.get("daily_day_key", ""))
	var saved_ids: Array = section.get("daily_ids", [])

	if saved_day_key != today_key or saved_ids.is_empty() or saved_ids.size() != _GetDailyTargetCount(amount):
		GenerateDailyRandom(amount)

	var result: Array = []
	for bonus_id in _GetSaveSection().get("daily_ids", []):
		var id := str(bonus_id)
		var bonus_data = _bonus_db.get(id, {})
		if typeof(bonus_data) != TYPE_DICTIONARY or bonus_data.is_empty():
			continue

		var entry = bonus_data.duplicate(true)
		entry["id"] = id
		entry["is_active"] = IsBoosterActive(id)
		entry["remaining_sec"] = GetBoosterRemainingSec(id)
		result.append(entry)

	return result


func GenerateDailyRandom(amount: int = DEFAULT_DAILY_RANDOM_COUNT) -> Array:
	_EnsureSaveSection()

	var pool := _GetDailyEligibleIds()
	var target_count = min(max(amount, 0), pool.size())
	var picked_ids: Array = []

	while picked_ids.size() < target_count and !pool.is_empty():
		var picked_id := _PickWeightedBonusId(pool)
		if picked_id.is_empty():
			break

		picked_ids.append(picked_id)
		pool.erase(picked_id)

	var section := _GetSaveSection()
	section["daily_day_key"] = _GetTodayKey()
	section["daily_ids"] = picked_ids.duplicate()

	GlobalSave.SyncSave(false)
	return picked_ids.duplicate()


func ActivateBooster(booster_id: String, spend_currency: bool = true) -> bool:
	_EnsureSaveSection()
	CleanupExpiredBoosters()

	var bonus_data := _GetBonusById(booster_id)
	if bonus_data.is_empty():
		push_warning("GlobalTimedBonus: bonus_id not found: %s" % booster_id)
		return false

	var duration_sec := int(bonus_data.get("duration_sec", 0))
	if duration_sec <= 0:
		push_warning("GlobalTimedBonus: invalid duration for bonus_id=%s" % booster_id)
		return false

	var section := _GetSaveSection()
	var active: Dictionary = section.get("active", {})
	var now_unix := int(Time.get_unix_time_from_system())
	var old_entry: Dictionary = active.get(booster_id, {})

	var stack_mode := str(bonus_data.get("stack_mode", "refresh"))
	if old_entry.is_empty():
		stack_mode = "refresh" if stack_mode.is_empty() else stack_mode

	if stack_mode == "ignore_if_active" and IsBoosterActive(booster_id):
		return false

	if spend_currency:
		var cost_currency := str(bonus_data.get("cost_currency", ""))
		var cost_amount := int(bonus_data.get("cost_amount", 0))

		if cost_amount > 0 and cost_currency != "":
			var current_amount := int(GlobalSave.GetCurrency(cost_currency))
			if current_amount < cost_amount:
				return false

			GlobalSave.RemoveCurrency(cost_currency, cost_amount)

	var start_unix := now_unix
	var end_unix := now_unix + duration_sec

	match stack_mode:
		"extend":
			if !old_entry.is_empty() and int(old_entry.get("end_unix", 0)) > now_unix:
				start_unix = int(old_entry.get("start_unix", now_unix))
				end_unix = int(old_entry.get("end_unix", now_unix)) + duration_sec
		"refresh":
			start_unix = now_unix
			end_unix = now_unix + duration_sec
		_:
			start_unix = now_unix
			end_unix = now_unix + duration_sec

	active[booster_id] = {
		"start_unix": start_unix,
		"end_unix": end_unix
	}

	section["active"] = active
	GlobalSave.SyncSave()
	GlobalSignals.SyncActivatedBooster.emit(booster_id)
	return true


func GetActivatedBoosterIds() -> Array:
	CleanupExpiredBoosters()

	var active: Dictionary = _GetSaveSection().get("active", {})
	var ids: Array = []
	for booster_id in active.keys():
		ids.append(str(booster_id))

	return ids


func GetActivatedBoosterData(booster_id: String) -> Dictionary:
	CleanupExpiredBoosters()

	var active: Dictionary = _GetSaveSection().get("active", {})
	if !active.has(booster_id):
		return {}

	var bonus_data := _GetBonusById(booster_id)
	if bonus_data.is_empty():
		return {}

	var active_entry: Dictionary = active.get(booster_id, {})
	return _BuildBonusRuntimeData(booster_id, bonus_data, active_entry)


func IsBoosterActive(booster_id: String) -> bool:
	var active_data := GetActivatedBoosterData(booster_id)
	return bool(active_data.get("is_active", false))


func GetBoosterRemainingSec(booster_id: String) -> int:
	var active_data := GetActivatedBoosterData(booster_id)
	return int(active_data.get("remaining_sec", 0))


func CleanupExpiredBoosters() -> void:
	_EnsureSaveSection()

	var section := _GetSaveSection()
	var active: Dictionary = section.get("active", {})
	if active.is_empty():
		return

	var now_unix := int(Time.get_unix_time_from_system())
	var changed := false

	for booster_id in active.keys():
		var entry: Dictionary = active.get(booster_id, {})
		var end_unix := int(entry.get("end_unix", 0))
		if end_unix <= now_unix:
			active.erase(booster_id)
			changed = true

	if changed:
		section["active"] = active
		GlobalSave.SyncSave(false)


func _EnsureSaveSection() -> void:
	if typeof(GlobalSave.save_data) != TYPE_DICTIONARY:
		return

	if !GlobalSave.save_data.has(SAVE_KEY):
		GlobalSave.save_data[SAVE_KEY] = {
			"active": {},
			"daily_day_key": "",
			"daily_ids": []
		}

	var section: Dictionary = GlobalSave.save_data[SAVE_KEY]

	if !section.has("active") or typeof(section["active"]) != TYPE_DICTIONARY:
		section["active"] = {}

	if !section.has("daily_day_key"):
		section["daily_day_key"] = ""

	if !section.has("daily_ids") or typeof(section["daily_ids"]) != TYPE_ARRAY:
		section["daily_ids"] = []


func _GetSaveSection() -> Dictionary:
	return GlobalSave.save_data.get(SAVE_KEY, {})


func _GetTodayKey() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [
		int(d.get("year", 1970)),
		int(d.get("month", 1)),
		int(d.get("day", 1))
	]


func _GetBonusById(booster_id: String) -> Dictionary:
	if _bonus_db.is_empty():
		LoadBonusDatabase()

	var data = _bonus_db.get(booster_id, {})
	if typeof(data) != TYPE_DICTIONARY:
		return {}

	return data


func _GetDailyEligibleIds() -> Array:
	var result: Array = []

	for bonus_id in _bonus_db.keys():
		var id := str(bonus_id)
		var data = _bonus_db.get(id, {})
		if typeof(data) != TYPE_DICTIONARY:
			continue

		if !bool(data.get("enabled", true)):
			continue

		if !bool(data.get("show_in_daily_random", true)):
			continue

		result.append(id)

	return result


func _PickWeightedBonusId(candidate_ids: Array) -> String:
	if candidate_ids.is_empty():
		return ""

	var total_weight := 0.0
	for bonus_id in candidate_ids:
		var data: Dictionary = _bonus_db.get(str(bonus_id), {})
		total_weight += max(0.0, float(data.get("daily_weight", data.get("weight", 1.0))))

	if total_weight <= 0.0:
		return str(candidate_ids[_rng.randi_range(0, candidate_ids.size() - 1)])

	var roll := _rng.randf_range(0.0, total_weight)
	var running := 0.0

	for bonus_id in candidate_ids:
		var data: Dictionary = _bonus_db.get(str(bonus_id), {})
		running += max(0.0, float(data.get("daily_weight", data.get("weight", 1.0))))
		if roll <= running:
			return str(bonus_id)

	return str(candidate_ids.back())


func _BuildBonusRuntimeData(booster_id: String, bonus_data: Dictionary, active_entry: Dictionary) -> Dictionary:
	var now_unix := int(Time.get_unix_time_from_system())
	var end_unix := int(active_entry.get("end_unix", 0))
	var remaining_sec = max(0, end_unix - now_unix)

	var result := bonus_data.duplicate(true)
	result["id"] = booster_id
	result["start_unix"] = int(active_entry.get("start_unix", 0))
	result["end_unix"] = end_unix
	result["remaining_sec"] = remaining_sec
	result["is_active"] = remaining_sec > 0

	return result


func _GetDailyTargetCount(amount: int) -> int:
	return min(max(amount, 0), _GetDailyEligibleIds().size())

func GetIcon(icon_str)->Texture2D:
	return load("res://art/bonus/"+icon_str+".tres")

func IsDailyBooster(booster_id: String) -> bool:
	var bonus_data := _GetBonusById(booster_id)
	if bonus_data.is_empty():
		return false

	return bool(bonus_data.get("show_in_daily_random", true))


func GetBoosterDataById(booster_id: String) -> Dictionary:
	_EnsureSaveSection()
	CleanupExpiredBoosters()

	var bonus_data := _GetBonusById(booster_id)
	if bonus_data.is_empty():
		return {}

	var result := bonus_data.duplicate(true)
	result["id"] = booster_id
	result["is_active"] = IsBoosterActive(booster_id)
	result["remaining_sec"] = GetBoosterRemainingSec(booster_id)
	return result


func GetNonDailyBoosterData(booster_id: String) -> Dictionary:
	var bonus_data := GetBoosterDataById(booster_id)
	if bonus_data.is_empty():
		return {}

	if IsDailyBooster(booster_id):
		return {}

	return bonus_data


func ActivateNonDailyBooster(booster_id: String, spend_currency: bool = true) -> bool:
	var bonus_data := _GetBonusById(booster_id)
	if bonus_data.is_empty():
		push_warning("GlobalTimedBonus: bonus_id not found: %s" % booster_id)
		return false

	if IsDailyBooster(booster_id):
		push_warning("GlobalTimedBonus: booster is part of daily pool, use ActivateBooster instead: %s" % booster_id)
		return false

	return ActivateBooster(booster_id, spend_currency)

func GetDailyTaskDayKey() -> String:
	var timed_bonuses = GlobalSave.save_data.get("timed_bonuses", {})
	return str(timed_bonuses.get("daily_day_key", ""))


func GetSecondsUntilDailyTaskReset() -> int:
	var saved_day_key := GetDailyTaskDayKey()

	var now := Time.get_datetime_dict_from_system(false)
	var today_key := "%04d-%02d-%02d" % [
		int(now.year),
		int(now.month),
		int(now.day)
	]

	# already expired / needs refresh
	if saved_day_key == "" or saved_day_key != today_key:
		return 0

	var today_midnight := {
		"year": int(now.year),
		"month": int(now.month),
		"day": int(now.day),
		"hour": 0,
		"minute": 0,
		"second": 0
	}

	var next_reset_unix := int(Time.get_unix_time_from_datetime_dict(today_midnight)) + 86400
	var now_unix := int(Time.get_unix_time_from_system())

	return max(0, next_reset_unix - now_unix)


func GetDailyTaskResetCountdownText() -> String:
	var left := GetSecondsUntilDailyTaskReset()

	var hours := left / 3600.0
	var minutes := (left % 3600) / 60.0
	var seconds := left % 60

	return "%02d:%02d:%02d" % [hours, minutes, seconds]
