extends Node
const CUR_SAVE_VERSION = 0.2



const SAVE_FILE = "user://savegame.json"
const UPGRADE_DATA = "res://data/upgrades/upgrade_db.json"


var save_data := {}
var save_timer : Timer = null

func _ready() -> void:
	CreateSaveTimer()
	LoadFromSave()
	RepapulateAllLaneBlocks()
	
func RepapulateAllLaneBlocks():
	GenerateNextBlocks(0,5)
	GenerateNextBlocks(1,5)
	GenerateNextBlocks(2,5)
	GenerateNextBlocks(3,5)
	GenerateNextBlocks(4,5)
	
func GenerateNextBlocks(lane_index:int,block_amount:int):
	var lane_data = GetLaneData(lane_index)
	if lane_data.block_data.is_empty():
		for x in block_amount:
			var block_data = GlobalBlockDatabase.spawn_block(lane_data.lane_depth+x,lane_index)
			lane_data.block_data.append(block_data)
		

func CreateSaveTimer():
	save_timer = Timer.new()
	save_timer.wait_time = 1.0
	save_timer.one_shot = true
	save_timer.timeout.connect(ForceSave)
	add_child(save_timer)
	
func SyncSave(emit_data_saved:=true):
	if save_timer.is_stopped():
		ForceSave()
		save_timer.start()
	if emit_data_saved:
		GlobalSignals.DataSaved.emit()
	
func ForceSave():
	var f = FileAccess.open(SAVE_FILE,FileAccess.WRITE)
	save_data["meta"]["save_version"] = CUR_SAVE_VERSION
	save_data["meta"]["last_saved_unix"] = Time.get_unix_time_from_system()
	
	var save_dup = save_data.duplicate()
	
	var json_string := JSON.stringify(save_dup, "\t")

	if f == null:
		push_error("SaveManager: Failed to open save file for writing: %s" % SAVE_FILE)
		return false

	f.store_string(json_string)
	
	f.close()
func LoadFromSave():
	if !FileAccess.file_exists(SAVE_FILE):
		save_data = BuildCleanSaveData()
		return

	var f = FileAccess.open(SAVE_FILE, FileAccess.READ)
	var json_text = f.get_as_text()
	f.close()

	var json := JSON.new()
	var error := json.parse(json_text)

	if error != OK:
		push_error("SaveManager: JSON parse error at line %d: %s" % [
			json.get_error_line(),
			json.get_error_message()
		])
		save_data = BuildCleanSaveData()
		return

	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("SaveManager: Save file root is not a Dictionary.")
		save_data = BuildCleanSaveData()
		return

	save_data = json.data
	EnsureUpgradeSchema()

func EnsureUpgradeSchema() -> void:
	var latest_upgrades = LoadUpgrades()
	if typeof(latest_upgrades) != TYPE_DICTIONARY:
		return

	if !save_data.has("upgrades") or typeof(save_data.upgrades) != TYPE_DICTIONARY:
		save_data["upgrades"] = latest_upgrades.duplicate(true)
		return

	for upgrade_id in latest_upgrades.keys():
		var latest_upgrade: Dictionary = latest_upgrades[upgrade_id]

		if !save_data.upgrades.has(upgrade_id):
			save_data.upgrades[upgrade_id] = latest_upgrade.duplicate(true)
			continue

		var current_upgrade: Dictionary = save_data.upgrades[upgrade_id]
		for key in latest_upgrade.keys():
			if !current_upgrade.has(key):
				current_upgrade[key] = latest_upgrade[key]


func BuildCleanSaveData():
	var res = {}
	res["currencies"] = {"coins":5000,"crystals":0,"energy":0} #default coins 25
	res["bot_inventory"]={
		"bot_db": [],
		"merge_free_slots":4
	}
	res["lanes"] = []
	res["lanes"].append({"auto_dig_unlocked":true,"bot_uid":int(-1),"dig_power":1.0,"dig_speed":1.0,"lane_index":int(0),"block_data":[],"lane_depth":int(0)})
	res["lanes"].append({"auto_dig_unlocked":false,"bot_uid":int(-1),"dig_power":1.0,"dig_speed":1.0,"lane_index":int(1),"block_data":[],"lane_depth":int(0)})
	res["lanes"].append({"auto_dig_unlocked":false,"bot_uid":int(-1),"dig_power":1.0,"dig_speed":1.0,"lane_index":int(2),"block_data":[],"lane_depth":int(0)})
	res["lanes"].append({"auto_dig_unlocked":false,"bot_uid":int(-1),"dig_power":1.0,"dig_speed":1.0,"lane_index":int(3),"block_data":[],"lane_depth":int(0)})
	res["lanes"].append({"auto_dig_unlocked":false,"bot_uid":int(-1),"dig_power":1.0,"dig_speed":1.0,"lane_index":int(4),"block_data":[],"lane_depth":int(0)})
	res["meta"] = {
		"created_unix":Time.get_unix_time_from_system(),
		"last_saved_unix":Time.get_unix_time_from_system(),
		"last_loaded_unix":Time.get_unix_time_from_system(),
		"save_version":CUR_SAVE_VERSION,
		"block_uid_serial": int(0)
		}
	res["progress"] = {
		"efficiency_mult": 1.0,
		"global_depth":0
	}
	res["milestones"] = {
		"completed_ids": [],
		"claimed_ids": []
	}
	res["player_stats"] = {
		"total_merges": 0,
		"boss_kills": 0,
		"max_depth_reached": 0,
		"highest_bot_level_ever": 0,
		"core_resets":0,
		"current_prestige":0
	}
	res["settings"] = {
		"music_enabled":true,
		"sfx_enabled":true,
		"vibration_enabled":true
	}
	res["global_upgrades"] = {
		"global_dig_power_level":0,
		"global_dig_speed_level":0,
		"offline_gain_level":0.0,
	}
	res["boss_progress"] = {
			"killed_depths": [],
			"killed_ids":[]
		}
	res["upgrades"] = LoadUpgrades()
	res["daily_quests"] = {
		"day_key": "",
		"active_ids": [],
		"progress": {},
		"claimed_ids": [],
		"completed_ids": []
	}
	res["relic_inv"]={
			"equipped_ids" : [],
			"owned" : {},
			"dust": 18,
			"unlocked_slots": 2
		}
	return res


func LoadUpgrades():
	var s = FileAccess.open(UPGRADE_DATA,FileAccess.READ)
	var json_text = s.get_as_text()
	s.close()
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
	
func GetLaneData(lane_index:int)->Dictionary:
	for x in save_data.lanes:
		if x.lane_index == lane_index:
			return x
	return {}

func GetCurrency(currency_type:String)->int:
	return save_data.currencies[currency_type]

func RemoveCurrency(currency_type:String,value:int) -> void:
	save_data.currencies[currency_type] = int(save_data.currencies[currency_type] - value)
	return
	
func AddCurrency(currency_type:String,value:int) -> void:
	save_data.currencies[currency_type] = int(save_data.currencies[currency_type] + value)
	GlobalSignals.CurrencyAdded.emit(currency_type,value)
	return
	
func ActivateLane(lane_index:int):
	for x in save_data.lanes:
		if x.lane_index == lane_index:
			x.auto_dig_unlocked = true
			if lane_index == 1:
				if !IsMilestoneCompleted("unlock_lane_2"):
					SetMilestoneToCompleted("unlock_lane_2")
			if lane_index == 2:
				if !IsMilestoneCompleted("unlock_lane_3"):
					SetMilestoneToCompleted("unlock_lane_3")
			if lane_index == 4:
				if !IsMilestoneCompleted("unlock_lane_5"):
					SetMilestoneToCompleted("unlock_lane_5")
			return
	
func GetBotDataFromMergeSlot(merge_slot)->Dictionary:
	for x in save_data.bot_inventory.bot_db:
		if x.merge_slot_id == merge_slot:
			return x
	return {}

func FindFreeMergeSlot() -> int:
	var max_merge_slots = int(save_data.bot_inventory.merge_free_slots)

	for slot_id in range(max_merge_slots):
		var is_taken := false

		for bot in save_data.bot_inventory.bot_db:
			if int(bot.get("merge_slot_id", -1)) == slot_id:
				is_taken = true
				break

		if !is_taken:
			return slot_id

	return -1

func FindFreeUID() -> int:
	var start_uid = 1000
	while true:
		var bot_data = FindBotDBFromUID(start_uid)
		if bot_data.is_empty():
			break
		start_uid += 1
	return start_uid

func FindBotDBFromUID(uid) -> Dictionary:
	for x in save_data.bot_inventory.bot_db:
		if x.uid == uid:
			return x
	return {}

func CreateSimpleBot() -> Dictionary:
	var res = {}
	var new_uid = FindFreeUID()
	res["uid"] = new_uid
	res["merge_slot_id"] = -1
	res["stats"] = {} #Change this based on other global stats.
	res["level"] = 1 #Change this based on other global stats.
	return res

func StoreUpdateBotData(new_bot_data:Dictionary) -> void:
	var bot_data = FindBotDBFromUID(new_bot_data.uid)
	if bot_data.is_empty():
		save_data.bot_inventory.bot_db.append(new_bot_data)
	else:
		for x in new_bot_data:
			bot_data[x] = new_bot_data[x]

func GetBotDataFromUID(bot_uid:int) -> Dictionary:
	for x in save_data.bot_inventory.bot_db:
		if x.uid == bot_uid:
			return x
	return {}
	
func RemoveBotByID(uid: int) -> void:
	for i in range(save_data.bot_inventory.bot_db.size()):
		if int(save_data.bot_inventory.bot_db[i].uid) == uid:
			save_data.bot_inventory.bot_db.remove_at(i)
			break

	for x in save_data.lanes:
		if int(x.bot_uid) == uid:
			x.bot_uid = -1
			break
			
func CombineBetween2MergeNodes(old_uid: int, new_uid: int) -> void:
	if old_uid == new_uid:
		return

	var old_merge_data = GetBotDataFromUID(old_uid)
	var new_merge_data = GetBotDataFromUID(new_uid)

	if old_merge_data.is_empty() or new_merge_data.is_empty():
		push_warning("CombineBetween2MergeNodes: one of the bots was not found")
		return

	# Optional stats merge
	if old_merge_data.has("stats") and typeof(old_merge_data.stats) == TYPE_DICTIONARY:
		if !new_merge_data.has("stats") or typeof(new_merge_data.stats) != TYPE_DICTIONARY:
			new_merge_data["stats"] = {}

		for stat in old_merge_data.stats:
			if !new_merge_data.stats.has(stat):
				new_merge_data.stats[stat] = old_merge_data.stats[stat]
			else:
				new_merge_data.stats[stat] += old_merge_data.stats[stat]

	new_merge_data.level = int(new_merge_data.level + 1)
	GlobalSave.SetHighestBotLevel(new_merge_data.level)
	GlobalDailyQuest.RegisterMergeCreated(new_merge_data.level)
	# clear old slot ownership before removing
	old_merge_data.merge_slot_id = -1
	if new_merge_data.level == 3:
		if !GlobalSave.IsMilestoneCompleted("bot_level_3"):
			GlobalSave.SetMilestoneToCompleted("bot_level_3")
	RemoveBotByID(old_uid)
	SyncSave()
	
func SwapBetween2BotsMergeToMerge(old_uid: int, new_uid: int) -> void:
	var old_bot = GetBotDataFromUID(old_uid)
	var new_bot = GetBotDataFromUID(new_uid)
	if old_bot.is_empty() or new_bot.is_empty():
		push_warning("SwapBetween2BotsMergeToMerge: one of the bots was not found")
		return

	var temp_slot := int(old_bot.merge_slot_id)
	old_bot.merge_slot_id = int(new_bot.merge_slot_id)
	new_bot.merge_slot_id = temp_slot


func FindLaneDataFromBotID(bot_id:int) -> Dictionary:
	for x in save_data.lanes:
		if x.bot_uid == bot_id:
			return x
	return {}
	
func SwapBetween2BotsMergeToDigBot(old_uid: int, new_uid: int) -> void:
	var old_bot = GetBotDataFromUID(old_uid)
	var new_bot = GetBotDataFromUID(new_uid)
	var new_lane_data = FindLaneDataFromBotID(new_uid)
	new_lane_data.bot_uid = int(old_uid)
	new_bot.merge_slot_id = int(old_bot.merge_slot_id)
	old_bot.merge_slot_id = int(-1)
	
func SwapBetween2BotsDigBoToMerge(old_uid: int, new_uid: int) -> void:
	var old_bot = GetBotDataFromUID(old_uid)
	var new_bot = GetBotDataFromUID(new_uid)
	var old_lane_data = FindLaneDataFromBotID(old_uid)

	old_lane_data.bot_uid = int(new_uid)
	old_bot.merge_slot_id = int(new_bot.merge_slot_id)
	new_bot.merge_slot_id = int(-1)
	
func MergeFromMergeToDigBot(merge_uid:int,digbot_uid:int):
	var merge_old_bot_data = GetBotDataFromUID(merge_uid)
	var digbot_data = GetBotDataFromUID(digbot_uid)
	var old_bot_stats = merge_old_bot_data.stats.duplicate()
	for stat in old_bot_stats:
		if !digbot_data.has(stat):
			digbot_data.stats[stat] = old_bot_stats[stat]
		else:
			digbot_data.stats[stat] += old_bot_stats[stat]
	digbot_data.level = int(digbot_data.level + 1)
	if digbot_data.level == 3:
		if !GlobalSave.IsMilestoneCompleted("bot_level_3"):
			GlobalSave.SetMilestoneToCompleted("bot_level_3")
	GlobalDailyQuest.RegisterMergeCreated(digbot_data.level)
	GlobalSave.SetHighestBotLevel(digbot_data.level)
	RemoveBotByID(merge_uid)
	
func MergeFromDigBotToMerge(digbot_uid: int, merge_uid: int) -> void:
	var digbot_data = GetBotDataFromUID(digbot_uid)
	var merge_bot_data = GetBotDataFromUID(merge_uid)

	if digbot_data.is_empty() or merge_bot_data.is_empty():
		push_warning("MergeFromDigBotToMerge: one of the bots was not found")
		return

	# make sure target has stats dictionary
	if !merge_bot_data.has("stats") or typeof(merge_bot_data.stats) != TYPE_DICTIONARY:
		merge_bot_data["stats"] = {}

	# merge stats from dragged dig-bot into target merge bot
	if digbot_data.has("stats") and typeof(digbot_data.stats) == TYPE_DICTIONARY:
		for stat in digbot_data.stats:
			if !merge_bot_data.stats.has(stat):
				merge_bot_data.stats[stat] = digbot_data.stats[stat]
			else:
				merge_bot_data.stats[stat] += digbot_data.stats[stat]

	# level up the target bot that stays in the merge slot
	merge_bot_data.level = int(merge_bot_data.level + 1)
	if merge_bot_data.level == 3:
		if !GlobalSave.IsMilestoneCompleted("bot_level_3"):
			GlobalSave.SetMilestoneToCompleted("bot_level_3")
	GlobalSave.SetHighestBotLevel(merge_bot_data.level)
	GlobalDailyQuest.RegisterMergeCreated(merge_bot_data.level)
	# remove dragged dig-bot from inventory and lane
	RemoveBotByID(digbot_uid)

func GetLaneDataByIndex(lane_index:int) -> Dictionary:
	for x in save_data.lanes:
		if x.lane_index == lane_index:
			return x
	return {}

func SetGlobalDepth(glob_depth:int):
	var cur_global_depth = save_data.progress.global_depth
	var best_depth = max(glob_depth, int(cur_global_depth))
	if best_depth > save_data.progress.global_depth:
		save_data.progress.global_depth = best_depth
	if save_data.player_stats.max_depth_reached < best_depth:
		save_data.player_stats.max_depth_reached = best_depth
	
	var cur_milestone_list = GlobalMilestone.GetMilestoneFromTargetTypeArray("reach_depth")
	if !cur_milestone_list.is_empty():
		
		for x in cur_milestone_list:
			
			if x.data.target_type == "reach_depth" && !IsMilestoneCompleted(x.id):
				if x.data.target_value <= save_data.player_stats.max_depth_reached:
					SetMilestoneToCompleted(x.id)
	
	
func SetHighestBotLevel(new_level:int)->void:
	if new_level > save_data.player_stats.highest_bot_level_ever:
		save_data.player_stats.highest_bot_level_ever = new_level

func SetTotalMerges(plus_merge:int =1)->void:
	save_data.player_stats.total_merges += plus_merge
	
	var cur_milestone_list = GlobalMilestone.GetMilestoneFromTargetTypeArray("merge_count")
	if !cur_milestone_list.is_empty():
		for x in cur_milestone_list:
			if x.data.target_type == "merge_count" && !IsMilestoneCompleted(x.id):
				if x.data.target_value <= save_data.player_stats.total_merges:
					SetMilestoneToCompleted(x.id)

func SetTotalBossKills(plus_bosses:int =1)->void:
	save_data.player_stats.boss_kills += plus_bosses
	var cur_milestone_list = GlobalMilestone.GetMilestoneFromTargetTypeArray("boss_kill_count")
	if !cur_milestone_list.is_empty():
		for x in cur_milestone_list:
			if x.data.target_type == "boss_kill_count" && !IsMilestoneCompleted(x.id):
				if x.data.target_value <= save_data.player_stats.boss_kills:
					SetMilestoneToCompleted(x.id)
	


func SetMilestoneToCompleted(milestone_key):
	#Check if completed
	if save_data.milestones.completed_ids.has(milestone_key):
		return
	#check if claimed
	if save_data.milestones.claimed_ids.has(milestone_key):
		return
	save_data.milestones.completed_ids.append(milestone_key)

func SetMilestoneToClaimed(milestone_key)->void:
	#Check if completed
	if save_data.milestones.completed_ids.has(milestone_key):
		save_data.milestones.claimed_ids.append(milestone_key)
		#save_data.milestones.completed_ids.erase(milestone_key)
func IsMilestoneCompleted(milestone_key):
	if save_data.milestones.completed_ids.has(milestone_key):
		return true
	if save_data.milestones.claimed_ids.has(milestone_key):
		return true
	return false
