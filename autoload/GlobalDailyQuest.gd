extends Node

signal daily_quests_generated(day_key: String)
signal daily_quest_progress_updated(quest_id: String, progress: int, target: int)
signal daily_quest_completed(quest_id: String)
signal daily_quest_claimed(quest_id: String)

const DAILY_QUEST_DB_PATH := "res://data/daily_quests/daily_quests.json"
const SAVE_KEY := "daily_quests"
const DEFAULT_DAILY_COUNT := 3

var _quest_db: Dictionary = {}
var _quest_pool: Array = []
var _quest_by_id: Dictionary = {}
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

func InitDailyQuestSystem() -> void:
	LoadQuestDatabase()
	_EnsureSaveSection()
	_ConnectRuntimeSignals()
	RefreshForToday()
	GlobalSignals.AllQuestsInited.emit()


func LoadQuestDatabase() -> bool:
	_quest_db.clear()
	_quest_pool.clear()
	_quest_by_id.clear()

	if !FileAccess.file_exists(DAILY_QUEST_DB_PATH):
		push_error("GlobalDailyQuest: Missing DB file: %s" % DAILY_QUEST_DB_PATH)
		return false

	var f := FileAccess.open(DAILY_QUEST_DB_PATH, FileAccess.READ)
	if f == null:
		push_error("GlobalDailyQuest: Failed to open DB file: %s" % DAILY_QUEST_DB_PATH)
		return false

	var json_text := f.get_as_text()
	f.close()

	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("GlobalDailyQuest: JSON parse error at line %d: %s" % [
			json.get_error_line(),
			json.get_error_message()
		])
		return false

	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("GlobalDailyQuest: Daily quest DB root must be a Dictionary.")
		return false

	_quest_db = json.data
	_quest_pool = _quest_db.get("quest_pool", [])

	for quest in _quest_pool:
		if typeof(quest) != TYPE_DICTIONARY:
			continue

		var quest_id := str(quest.get("id", ""))
		if quest_id.is_empty():
			continue

		_quest_by_id[quest_id] = quest

	return true


func RefreshForToday() -> void:
	_EnsureSaveSection()

	var section := _GetSaveSection()
	var today_key := _GetTodayKey()
	var active_ids: Array = section.get("active_ids", [])

	if str(section.get("day_key", "")) != today_key or active_ids.is_empty():
		GenerateNewSet()


func GenerateNewSet() -> void:
	_EnsureSaveSection()

	var eligible_pool := _GetEligibleQuestPool()
	var daily_count := int(_quest_db.get("daily_count", DEFAULT_DAILY_COUNT)) + GlobalStats.GetAdditionalDailyQuestLimit()

	var selected_ids: Array = []
	var selected_lookup := {}
	var type_counts := {}
	var type_caps := {
		"merge_bots": 1,
		"buy_upgrades": 1,
		"defeat_bosses": 1
	}

	# Prefer at least 1 break quest if possible
	var break_candidates: Array = []
	for quest in eligible_pool:
		if str(quest.get("objective_type", "")) == "break_blocks":
			break_candidates.append(quest)

	if !break_candidates.is_empty():
		var break_pick := _PickWeightedQuest(break_candidates, selected_lookup, type_counts, type_caps)
		if !break_pick.is_empty():
			_AcceptPickedQuest(break_pick, selected_ids, selected_lookup, type_counts)

	while selected_ids.size() < daily_count:
		var picked := _PickWeightedQuest(eligible_pool, selected_lookup, type_counts, type_caps)

		# fallback if caps are too strict
		if picked.is_empty():
			picked = _PickWeightedQuest(eligible_pool, selected_lookup, type_counts, {})

		if picked.is_empty():
			break

		_AcceptPickedQuest(picked, selected_ids, selected_lookup, type_counts)

	var section := _GetSaveSection()
	section["day_key"] = _GetTodayKey()
	section["active_ids"] = selected_ids.duplicate()
	section["progress"] = {}
	section["claimed_ids"] = []
	section["completed_ids"] = []

	for quest_id in selected_ids:
		section["progress"][quest_id] = 0

	GlobalSave.SyncSave(false)
	daily_quests_generated.emit(str(section["day_key"]))


func GetQuest(quest_id: String) -> Dictionary:
	var template := GetQuestTemplate(quest_id)
	if template.is_empty():
		return {}

	var result := template.duplicate(true)
	result["progress"] = GetQuestProgress(quest_id)
	result["target"] = int(template.get("target", 0))
	result["is_complete"] = IsQuestComplete(quest_id)
	result["is_claimed"] = IsQuestClaimed(quest_id)
	result["is_active"] = IsQuestActive(quest_id)

	return result


func GetQuestTemplate(quest_id: String) -> Dictionary:
	if !_quest_by_id.has(quest_id):
		return {}
	return _quest_by_id[quest_id]


func GetAllActiveQuests() -> Array:
	RefreshForToday()

	var result: Array = []
	for quest_id in GetActiveQuestIds():
		result.append(GetQuest(str(quest_id)))
	return result


func GetActiveQuestIds() -> Array:
	_EnsureSaveSection()
	return _GetSaveSection().get("active_ids", []).duplicate()


func GetQuestProgress(quest_id: String) -> int:
	_EnsureSaveSection()
	var progress_dict: Dictionary = _GetSaveSection().get("progress", {})
	return int(progress_dict.get(quest_id, 0))


func IsQuestActive(quest_id: String) -> bool:
	return GetActiveQuestIds().has(quest_id)


func IsQuestComplete(quest_id: String) -> bool:
	var template := GetQuestTemplate(quest_id)
	if template.is_empty():
		return false

	var target := int(template.get("target", 0))
	if target <= 0:
		return false

	return GetQuestProgress(quest_id) >= target


func IsQuestClaimed(quest_id: String) -> bool:
	_EnsureSaveSection()
	var claimed_ids: Array = _GetSaveSection().get("claimed_ids", [])
	return claimed_ids.has(quest_id)


func HasClaimableQuest() -> bool:
	for quest_id in GetActiveQuestIds():
		if IsQuestComplete(str(quest_id)) and !IsQuestClaimed(str(quest_id)):
			return true
	return false


func AddProgress(objective_type: String, amount: int = 1, event_data: Dictionary = {}) -> void:
	if amount <= 0:
		return

	_EnsureSaveSection()
	RefreshForToday()

	var changed := false

	for quest_id_variant in GetActiveQuestIds():
		var quest_id := str(quest_id_variant)
		var template := GetQuestTemplate(quest_id)

		if template.is_empty():
			continue

		if str(template.get("objective_type", "")) != objective_type:
			continue

		if IsQuestClaimed(quest_id):
			continue

		var filters: Dictionary = template.get("filters", {})
		if !_DoesQuestMatchFilters(filters, event_data):
			continue

		var target := int(template.get("target", 0))
		var old_progress := GetQuestProgress(quest_id)
		var new_progress = min(target, old_progress + amount)

		if new_progress == old_progress:
			continue

		_SetQuestProgress(quest_id, new_progress)
		daily_quest_progress_updated.emit(quest_id, new_progress, target)

		changed = true

		if new_progress >= target and !_IsMarkedCompleted(quest_id):
			_MarkCompleted(quest_id)
			daily_quest_completed.emit(quest_id)

	if changed:
		GlobalSave.SyncSave()

	
func ClaimQuest(quest_id: String) -> bool:
	RefreshForToday()

	if !IsQuestActive(quest_id):
		return false

	if !IsQuestComplete(quest_id):
		return false

	if IsQuestClaimed(quest_id):
		return false

	var template := GetQuestTemplate(quest_id)
	if template.is_empty():
		return false

	var reward: Dictionary = template.get("reward", {})
	_GrantReward(reward)

	var section := _GetSaveSection()
	var claimed_ids: Array = section.get("claimed_ids", [])
	if !claimed_ids.has(quest_id):
		claimed_ids.append(quest_id)
		section["claimed_ids"] = claimed_ids

	daily_quest_claimed.emit(quest_id)
	return true


func RegisterMergeCreated(result_bot_level: int) -> void:
	AddProgress("merge_bots", 1, {
		"result_bot_level": result_bot_level
	})


func RegisterUpgradeBought(upgrade_id: String, upgrade_group: String) -> void:
	AddProgress("buy_upgrades", 1, {
		"upgrade_id": upgrade_id,
		"upgrade_group": upgrade_group
	})

func RegisterBlockBroken(block_id: String = "", block_type: String = "") -> void:
	AddProgress("break_blocks", 1, {
		"block_id": block_id,
		"block_type": block_type
	})


func RegisterBlocksBroken(amount: int, block_id: String = "", block_type: String = "") -> void:
	AddProgress("break_blocks", amount, {
		"block_id": block_id,
		"block_type": block_type
	})



func RegisterMergeCount(amount: int = 1) -> void:
	AddProgress("merge_bots", amount, {})



func RegisterUpgradeGroupBought(upgrade_group: String, amount: int = 1) -> void:
	AddProgress("buy_upgrades", amount, {
		"upgrade_group": upgrade_group
	})


func RegisterTap(amount: int = 1) -> void:
	AddProgress("tap_times", amount, {})


func RegisterDamageDealt(amount: int) -> void:
	AddProgress("deal_damage", amount, {})


func RegisterCoinsEarned(amount: int) -> void:
	AddProgress("earn_coins", amount, {})


func RegisterBossDefeated(boss_id: String = "", boss_type: String = "") -> void:
	AddProgress("defeat_bosses", 1, {
		"boss_id": boss_id,
		"boss_type": boss_type
	})


func RegisterLaneUnlocked(lane_index: int) -> void:
	AddProgress("unlock_lanes", 1, {
		"lane_index": lane_index
	})
	
func DebugForceGenerateNewSet() -> void:
	_EnsureSaveSection()
	_GetSaveSection()["day_key"] = ""
	GenerateNewSet()



func _EnsureSaveSection() -> void:
	if typeof(GlobalSave.save_data) != TYPE_DICTIONARY:
		return

	if !GlobalSave.save_data.has(SAVE_KEY):
		GlobalSave.save_data[SAVE_KEY] = {
			"day_key": "",
			"active_ids": [],
			"progress": {},
			"claimed_ids": [],
			"completed_ids": []
		}

	var section: Dictionary = GlobalSave.save_data[SAVE_KEY]

	if !section.has("day_key"):
		section["day_key"] = ""

	if !section.has("active_ids"):
		section["active_ids"] = []

	if !section.has("progress"):
		section["progress"] = {}

	if !section.has("claimed_ids"):
		section["claimed_ids"] = []

	if !section.has("completed_ids"):
		section["completed_ids"] = []


func _GetSaveSection() -> Dictionary:
	return GlobalSave.save_data.get(SAVE_KEY, {})


func _SetQuestProgress(quest_id: String, value: int) -> void:
	var section := _GetSaveSection()
	var progress_dict: Dictionary = section.get("progress", {})
	progress_dict[quest_id] = value
	section["progress"] = progress_dict


func _IsMarkedCompleted(quest_id: String) -> bool:
	var completed_ids: Array = _GetSaveSection().get("completed_ids", [])
	return completed_ids.has(quest_id)


func _MarkCompleted(quest_id: String) -> void:
	var section := _GetSaveSection()
	var completed_ids: Array = section.get("completed_ids", [])
	if !completed_ids.has(quest_id):
		completed_ids.append(quest_id)
		section["completed_ids"] = completed_ids


func _GetTodayKey() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [
		int(d.get("year", 1970)),
		int(d.get("month", 1)),
		int(d.get("day", 1))
	]


func _GetEligibleQuestPool() -> Array:
	var result: Array = []

	for quest in _quest_pool:
		if typeof(quest) != TYPE_DICTIONARY:
			continue

		if _QuestMeetsRequirements(quest):
			result.append(quest)

	return result


func _QuestMeetsRequirements(quest: Dictionary) -> bool:
	var requirements: Dictionary = quest.get("requirements", {})

	var min_depth := int(requirements.get("min_depth", 0))
	if _GetPlayerMaxDepth() < min_depth:
		return false

	var min_lane_unlocked := int(requirements.get("min_lane_unlocked", 1))
	if _GetUnlockedLaneCount() < min_lane_unlocked:
		return false

	return true


func _GetPlayerMaxDepth() -> int:
	if typeof(GlobalSave.save_data) != TYPE_DICTIONARY:
		return 0

	var player_stats: Dictionary = GlobalSave.save_data.get("player_stats", {})
	var progress: Dictionary = GlobalSave.save_data.get("progress", {})

	return max(
		int(player_stats.get("max_depth_reached", 0)),
		int(progress.get("global_depth", 0))
	)


func _GetUnlockedLaneCount() -> int:
	if typeof(GlobalSave.save_data) != TYPE_DICTIONARY:
		return 0

	var count := 0
	var lanes: Array = GlobalSave.save_data.get("lanes", [])

	for lane_data in lanes:
		if bool(lane_data.get("auto_dig_unlocked", false)):
			count += 1

	return count


func _PickWeightedQuest(
	candidates: Array,
	selected_lookup: Dictionary,
	type_counts: Dictionary,
	type_caps: Dictionary
) -> Dictionary:
	var filtered: Array = []
	var total_weight := 0.0

	for quest in candidates:
		if typeof(quest) != TYPE_DICTIONARY:
			continue

		var quest_id := str(quest.get("id", ""))
		if quest_id.is_empty():
			continue

		if selected_lookup.has(quest_id):
			continue

		var objective_type := str(quest.get("objective_type", ""))
		var current_count := int(type_counts.get(objective_type, 0))
		var cap := int(type_caps.get(objective_type, -1))

		if cap >= 0 and current_count >= cap:
			continue

		var weight = max(1.0, float(quest.get("weight", 1.0)))
		filtered.append({
			"quest": quest,
			"weight": weight
		})
		total_weight += weight

	if filtered.is_empty():
		return {}

	var roll := _rng.randf_range(0.0, total_weight)
	var running := 0.0

	for entry in filtered:
		running += float(entry["weight"])
		if roll <= running:
			return entry["quest"]

	return filtered[filtered.size() - 1]["quest"]


func _AcceptPickedQuest(
	quest: Dictionary,
	selected_ids: Array,
	selected_lookup: Dictionary,
	type_counts: Dictionary
) -> void:
	var quest_id := str(quest.get("id", ""))
	if quest_id.is_empty():
		return

	var objective_type := str(quest.get("objective_type", ""))

	selected_ids.append(quest_id)
	selected_lookup[quest_id] = true
	type_counts[objective_type] = int(type_counts.get(objective_type, 0)) + 1


func _DoesQuestMatchFilters(filters: Dictionary, event_data: Dictionary) -> bool:
	for key in filters.keys():
		if !event_data.has(key):
			return false

		var filter_value = filters[key]
		var event_value = event_data[key]

		# Fixes JSON float/int mismatch, for example:
		# filter = 2.0, event = 2
		if _AreBothNumeric(filter_value, event_value):
			if int(filter_value) != int(event_value):
				return false
			continue

		if str(filter_value) != str(event_value):
			return false

	return true

func _AreBothNumeric(a, b) -> bool:
	var a_type := typeof(a)
	var b_type := typeof(b)

	var a_is_number := a_type == TYPE_INT or a_type == TYPE_FLOAT
	var b_is_number := b_type == TYPE_INT or b_type == TYPE_FLOAT

	return a_is_number and b_is_number
	
func _GrantReward(reward: Dictionary) -> void:
	for currency_type in ["coins", "crystals", "energy"]:
		var value := int(reward.get(currency_type, 0))
		if value > 0:
			GlobalSave.AddCurrency(currency_type, value)


func _ConnectRuntimeSignals() -> void:
	var digging_process = get_node_or_null("/root/GlobalDiggingProcess")
	if digging_process != null and !digging_process.block_destroyed.is_connected(_OnBlockDestroyed):
		digging_process.block_destroyed.connect(_OnBlockDestroyed)


func _OnBlockDestroyed(lane_index: int, _block_uid: String) -> void:
	if lane_index < 0:
		return

	if lane_index >= GlobalSave.save_data.get("lanes", []).size():
		return

	var lane_data: Dictionary = GlobalSave.save_data["lanes"][lane_index]
	if lane_data.get("block_data", []).is_empty():
		return

	# In your current digging flow, block_destroyed emits before the front block is removed,
	# so lane_data.block_data[0] is still the destroyed block here.


func GetMostProgressedActiveQuest(include_completed: bool = true, include_claimed: bool = false) -> Dictionary:
	RefreshForToday()

	var best_quest: Dictionary = {}
	var best_ratio := -1.0
	var zero_progress_quests: Array = []

	for quest_id_variant in GetActiveQuestIds():
		var quest_id := str(quest_id_variant)
		var quest := GetQuest(quest_id)

		if quest.is_empty():
			continue

		if !include_completed and bool(quest.get("is_complete", false)):
			continue

		if !include_claimed and bool(quest.get("is_claimed", false)):
			continue

		var target = max(1, int(quest.get("target", 1)))
		var progress := int(quest.get("progress", 0))
		var ratio := float(progress) / float(target)

		if progress <= 0:
			zero_progress_quests.append(quest)

		if ratio > best_ratio:
			best_ratio = ratio
			best_quest = quest

	# if all eligible quests are still at 0 progress,
	# return a random zero-progress quest instead
	if best_ratio <= 0.0 and !zero_progress_quests.is_empty():
		var random_index := _rng.randi_range(0, zero_progress_quests.size() - 1)
		var random_quest: Dictionary = zero_progress_quests[random_index]
		random_quest["progress_ratio"] = 0.0
		return random_quest

	if !best_quest.is_empty():
		best_quest["progress_ratio"] = best_ratio
	return best_quest
	

#USE SYSTEM LIKE THIS:
# when merge succeeds
#GlobalDailyQuest.RegisterMergeCreated(new_bot_level)
#
## when upgrade is bought
#GlobalDailyQuest.RegisterUpgradeBought(upgrade_id, upgrade_group)
