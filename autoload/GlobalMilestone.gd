extends Node

const MILESTONE_FILE = "res://data/upgrades/milestone_db.json"
var milestone_db = {}
func _ready() -> void:
	milestone_db = LoadMilestoneDB()

	
func LoadMilestoneDB():
	var f = FileAccess.open(MILESTONE_FILE,FileAccess.READ)
	var json_text = f.get_as_text()
	f.close()
	
	var json := JSON.new()
	var error := json.parse(json_text)

	if error != OK:
		push_error("SaveManager: JSON parse error at line %d: %s" % [
			json.get_error_line(),
			json.get_error_message()
		])
		return
		
	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("SaveManager: Save file root is not a Dictionary.")
		return

	return json.data

func get_next_milestone() -> Dictionary:
	var milestone_dict: Dictionary = milestone_db.get("milestones", {})
	var milestone_list: Array = []

	for milestone_id in milestone_dict.keys():
		var data: Dictionary = milestone_dict[milestone_id]
		milestone_list.append({
			"id": milestone_id,
			"data": data
		})

	milestone_list.sort_custom(func(a, b):
		return int(a["data"].get("order", 999999)) < int(b["data"].get("order", 999999))
	)

	# 1) completed but not claimed
	for entry in milestone_list:
		var milestone_id: String = entry["id"]
		var data: Dictionary = entry["data"]

		if is_milestone_completed(milestone_id) and not is_milestone_claimed(milestone_id):
			return {
				"id": milestone_id,
				"title": data.get("title", ""),
				"description": data.get("description", ""),
				"order": data.get("order", 0),
				"category": data.get("category", ""),
				"target_type": data.get("target_type", ""),
				"target_key": data.get("target_key", ""),
				"target_value": data.get("target_value", 0),
				"is_completed": true,
				"is_claimed": false,
				"can_claim": true,
				"reward_type": data.get("reward_type", ""),
				"reward_value": data.get("reward_value", 0),
				"auto_claim": data.get("auto_claim", true)
			}

	# 2) first not completed by order
	for entry in milestone_list:
		var milestone_id: String = entry["id"]
		var data: Dictionary = entry["data"]

		if is_milestone_completed(milestone_id):
			continue

		return {
			"id": milestone_id,
			"title": data.get("title", ""),
			"description": data.get("description", ""),
			"order": data.get("order", 0),
			"category": data.get("category", ""),
			"target_type": data.get("target_type", ""),
			"target_key": data.get("target_key", ""),
			"target_value": data.get("target_value", 0),
			"is_completed": false,
			"is_claimed": false,
			"can_claim": false,
			"reward_type": data.get("reward_type", ""),
			"reward_value": data.get("reward_value", 0),
			"auto_claim": data.get("auto_claim", true)
		}

	return {}

func is_milestone_completed(milestone_id: String) -> bool:
	return GlobalSave.save_data.get("milestones", {}).get("completed_ids", []).has(milestone_id)


func is_milestone_claimed(milestone_id: String) -> bool:
	return GlobalSave.save_data.get("milestones", {}).get("claimed_ids", []).has(milestone_id)

func GetMilestoneFromID(milestone_id:String)->Dictionary:
	return milestone_db.milestones[milestone_id]

func GetMilestoneFromTargetTypeArray(target_type:String)->Array:
	var res_data = []
	for x in milestone_db.milestones:
		if milestone_db.milestones[x].target_type == target_type:
			res_data.append({"data":milestone_db.milestones[x],"id":x})
	return res_data

func get_milestone_current_value(data: Dictionary) -> float:
	var target_type: String = data.get("target_type", "")

	match target_type:
		"own_bot_count":
			return float(get_total_owned_bot_count())

		"reach_depth":
			return float(GlobalSave.save_data.player_stats.max_depth_reached)

		"upgrade_level":
			return float(GlobalSave.save_data.upgrades.tap_damage.level)

		"merge_count":
			return float(GlobalSave.save_data.player_stats.total_merges)

		"unlock_lane_count":
			return float(get_unlocked_lane_count())

		"boss_kill_count":
			return float(GlobalSave.save_data.player_stats.boss_kills)

		"own_bot_level":
			return float(get_highest_bot_level_owned())

		_:
			return 0.0

func get_highest_bot_level_owned()->int:
	#level 3 or more
	var bot_count = 0
	for x in GlobalSave.save_data.bot_inventory.bot_db:
		if x.level >= 3:
			bot_count += 1
	return bot_count
	
func get_unlocked_lane_count()->int:
	var lane_count = 0
	for x in GlobalSave.save_data.lanes:
		if x.auto_dig_unlocked:
			lane_count += 1
	return int(lane_count)
	
func get_total_owned_bot_count():
	return GlobalSave.save_data.bot_inventory.bot_db.size()
