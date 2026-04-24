extends Node
const CUR_SAVE_VERSION = 0.2



const SAVE_FILE = "user://savegame.json"
const UPGRADE_DATA = "res://data/upgrades/upgrade_db.json"


var save_data := {}
var save_timer : Timer = null

func _ready() -> void:
	CreateSaveTimer()
	LoadFromSave()
	AdjustNewData()
	RepapulateAllLaneBlocks()
	
	
func MigrateBlockHpToBigNumbers() -> void:
	if !save_data.has("lanes"):
		return

	for lane in save_data.lanes:
		if !lane.has("block_data"):
			continue

		for block in lane.block_data:
			if typeof(block) != TYPE_DICTIONARY:
				continue

			if block.has("hp"):
				block.hp = GlobalBigNumber.ToBig(block.hp)

			if block.has("max_hp"):
				block.max_hp = GlobalBigNumber.ToBig(block.max_hp)

			if block.has("base_hp"):
				block.base_hp = GlobalBigNumber.ToBig(block.base_hp)
				
func AdjustNewData():
	if !GlobalSave.save_data.progress.has("total_bots_bought_this_reset"):
		GlobalSave.save_data.progress["total_bots_bought_this_reset"] = 0

	if !GlobalSave.save_data.has("offline_mining") or typeof(GlobalSave.save_data.offline_mining) != TYPE_DICTIONARY:
		GlobalSave.save_data["offline_mining"] = {
			"selected_band_index": -1
		}
	elif !GlobalSave.save_data.offline_mining.has("selected_band_index"):
		GlobalSave.save_data.offline_mining["selected_band_index"] = -1
	
	#Removing the flat dig_speed dig_power from the bots
	for x in save_data.bot_inventory.bot_db:
		if x.has("stats"):
			if x.stats.has("dig_power"):
				x.stats.erase("dig_power")
			if x.stats.has("dig_speed"):
				x.stats.erase("dig_speed")
	
	#Adjusting Bot Shop branch skill
	if !save_data.progress.has("free_bot_count"):
		
		save_data.progress["free_bot_count"] = 0
	MigrateBlockHpToBigNumbers()
	
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

func PrepareSaveMeta() -> void:
	if !save_data.has("meta") or typeof(save_data.meta) != TYPE_DICTIONARY:
		save_data["meta"] = {}

	save_data.meta["save_version"] = CUR_SAVE_VERSION
	save_data.meta["last_saved_unix"] = Time.get_unix_time_from_system()
	
func LoadingTimeStamp():
	if !GlobalSave.save_data.has("meta"):
		GlobalSave.save_data["meta"] = {}
	GlobalSave.save_data.meta["last_loaded_unix"] = Time.get_unix_time_from_system()
	
func ForceSave():
	PrepareSaveMeta()
	var f = FileAccess.open(SAVE_FILE,FileAccess.WRITE)
	
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
		LoadingTimeStamp()
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
		LoadingTimeStamp()
		return

	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("SaveManager: Save file root is not a Dictionary.")
		save_data = BuildCleanSaveData()
		LoadingTimeStamp()
		return

	save_data = json.data
	LoadingTimeStamp()
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
	res["currencies"] = {"coins":0,"crystals":0,"energy":0} #default coins 0
	res["bot_inventory"]={
		"bot_db": [],
		"merge_free_slots":4
	}
	res["lanes"] = []
	res["lanes"].append({"auto_dig_unlocked":true,"bot_uid":int(-1),"dig_power":1.0,"dig_speed":1.0,"lane_index":int(0),"block_data":[],"lane_depth":int(0),"last_cleared_depth":int(-1)})
	res["lanes"].append({"auto_dig_unlocked":false,"bot_uid":int(-1),"dig_power":1.0,"dig_speed":1.0,"lane_index":int(1),"block_data":[],"lane_depth":int(0),"last_cleared_depth":int(-1)})
	res["lanes"].append({"auto_dig_unlocked":false,"bot_uid":int(-1),"dig_power":1.0,"dig_speed":1.0,"lane_index":int(2),"block_data":[],"lane_depth":int(0),"last_cleared_depth":int(-1)})
	res["lanes"].append({"auto_dig_unlocked":false,"bot_uid":int(-1),"dig_power":1.0,"dig_speed":1.0,"lane_index":int(3),"block_data":[],"lane_depth":int(0),"last_cleared_depth":int(-1)})
	res["lanes"].append({"auto_dig_unlocked":false,"bot_uid":int(-1),"dig_power":1.0,"dig_speed":1.0,"lane_index":int(4),"block_data":[],"lane_depth":int(0),"last_cleared_depth":int(-1)})
	res["meta"] = {
		"created_unix":Time.get_unix_time_from_system(),
		"last_saved_unix":Time.get_unix_time_from_system(),
		"last_loaded_unix":Time.get_unix_time_from_system(),
		"save_version":CUR_SAVE_VERSION,
		"block_uid_serial": int(0)
		}
	res["progress"] = {
		"efficiency_mult": 1.0,
		"global_depth":0,
		"total_bots_bought_this_reset":0,
		"free_bot_count":0
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
		"current_prestige":0,
		"total_bots_bought": 0,
		
		"total_bots_got_free":0
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
	res["reward_chests"] = {
		"queue": []
	}
	res["skill_tree"] = {
		"tree_id":"",
		"version":1,
		"node_levels": {}
	}
	res["timed_bonuses"] = {
		"active": {},
		"daily_day_key": "",
		"daily_ids": []
	}
	res["daily_free_bot"]={
			"day_key":"",
			"amount":2,
			"mythic_amount":1
		}
	res["daily_watch_ads"]={
		"day_key": ""
	}
	res["offline_mining"] = {
		"selected_band_index": -1
	}
	return res

func GetDailyFreeBot():
	return save_data.daily_free_bot
	
	
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

func GetCurrency(currency_type: String) -> int:
	match currency_type:
		"dust":
			return int(save_data.get("relic_inv",0).get("dust",0))
		_: #int(save_data.currencies[currency_type])
			return int(save_data.get("currencies",0).get(currency_type,0))


func RemoveCurrency(currency_type:String, value:int) -> void:
	match currency_type:
		"dust":
			if !save_data.has("relic_inv") or typeof(save_data.relic_inv) != TYPE_DICTIONARY:
				save_data["relic_inv"] = { "dust": 0 }
			save_data.relic_inv["dust"] = maxi(0, int(save_data.relic_inv.get("dust", 0)) - value)
		_:
			if !save_data.has("currencies"):
				save_data["currencies"] = {}
			if !save_data.currencies.has(currency_type):
				save_data.currencies[currency_type] = 0
			save_data.currencies[currency_type] = maxi(0, int(save_data.currencies[currency_type]) - value)


func AddCurrency(currency_type:String, value:int) -> void:
	match currency_type:
		"dust":
			if !save_data.has("relic_inv") or typeof(save_data.relic_inv) != TYPE_DICTIONARY:
				save_data["relic_inv"] = { "dust": 0 }
			save_data.relic_inv["dust"] = int(save_data.relic_inv.get("dust", 0) + value)
		_:
			if !save_data.has("currencies"):
				save_data["currencies"] = {}
			if !save_data.currencies.has(currency_type):
				save_data.currencies[currency_type] = 0
			save_data.currencies[currency_type] = int(save_data.currencies[currency_type] + value)
	GlobalSignals.CurrencyAdded.emit(currency_type, value)
	

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
	var max_merge_slots = GlobalStats.GetFreeMergeSlots()

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

func CreateSimpleBot(by_rank:int=0) -> Dictionary:
	var cur_level := 1
	var res = {}
	var new_uid = FindFreeUID()
	var rolled_data : Dictionary = {}
	if by_rank == 0:
		rolled_data = GlobalBotStats.RollBotStats(cur_level)
	else:
		rolled_data = GlobalBotStats.RollBotStatsByRank(by_rank,cur_level)

	res["uid"] = new_uid
	res["merge_slot_id"] = -1
	res["level"] = cur_level
	res["rank"] = int(rolled_data.get("rank", 0))
	res["stats"] = rolled_data.get("stats", {})
	return res
	

func StoreUpdateBotData(new_bot_data:Dictionary,free_bot := false) -> void:
	var bot_data = FindBotDBFromUID(new_bot_data.uid)
	if bot_data.is_empty():
		save_data.bot_inventory.bot_db.append(new_bot_data)
		if !free_bot:
			save_data.player_stats.total_bots_bought += 1
			save_data.progress.total_bots_bought_this_reset += 1
		else:
			save_data.player_stats.total_bots_got_free += 1
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

	_EnsureBotMergeFields(old_merge_data)
	_EnsureBotMergeFields(new_merge_data)

	new_merge_data["stats"] = _MergeBotStatsDict(new_merge_data.stats, old_merge_data.stats)
	new_merge_data["rank"] = _GetMergedBotRank(
		int(new_merge_data.get("rank", 0)),
		int(old_merge_data.get("rank", 0))
	)

	_ApplyMergedBotProgress(new_merge_data)

	RemoveBotByID(old_uid)
	CheckChanceForFreeBotOnMerge()
	GlobalMusic.VibrationMed()
	
func CheckChanceForFreeBotOnMerge():
	if GlobalStats.HasChanceToSpawmNewBot():
		var free_merge_slot = GlobalSave.FindFreeMergeSlot()
		if free_merge_slot == -1:
			return
		var simple_bot = CreateSimpleBot()
		GlobalSave.StoreUpdateBotData(simple_bot)
		
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
	
func MergeFromMergeToDigBot(merge_uid: int, digbot_uid: int) -> void:
	var merge_old_bot_data = GetBotDataFromUID(merge_uid)
	var digbot_data = GetBotDataFromUID(digbot_uid)

	if merge_old_bot_data.is_empty() or digbot_data.is_empty():
		push_warning("MergeFromMergeToDigBot: one of the bots was not found")
		return

	_EnsureBotMergeFields(merge_old_bot_data)
	_EnsureBotMergeFields(digbot_data)

	digbot_data["stats"] = _MergeBotStatsDict(digbot_data.stats, merge_old_bot_data.stats)
	digbot_data["rank"] = _GetMergedBotRank(
		int(digbot_data.get("rank", 0)),
		int(merge_old_bot_data.get("rank", 0))
	)

	_ApplyMergedBotProgress(digbot_data)

	RemoveBotByID(merge_uid)
	CheckChanceForFreeBotOnMerge()
	GlobalMusic.VibrationMed()
	
func MergeFromDigBotToMerge(digbot_uid: int, merge_uid: int) -> void:
	var digbot_data = GetBotDataFromUID(digbot_uid)
	var merge_bot_data = GetBotDataFromUID(merge_uid)

	if digbot_data.is_empty() or merge_bot_data.is_empty():
		push_warning("MergeFromDigBotToMerge: one of the bots was not found")
		return

	_EnsureBotMergeFields(digbot_data)
	_EnsureBotMergeFields(merge_bot_data)

	merge_bot_data["stats"] = _MergeBotStatsDict(merge_bot_data.stats, digbot_data.stats)
	merge_bot_data["rank"] = _GetMergedBotRank(
		int(merge_bot_data.get("rank", 0)),
		int(digbot_data.get("rank", 0))
	)

	_ApplyMergedBotProgress(merge_bot_data)

	RemoveBotByID(digbot_uid)
	CheckChanceForFreeBotOnMerge()
	GlobalMusic.VibrationMed()

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

func _EnsureBotMergeFields(bot_data: Dictionary) -> void:
	if !bot_data.has("stats") or typeof(bot_data.stats) != TYPE_DICTIONARY:
		bot_data["stats"] = {}

	if !bot_data.has("rank"):
		bot_data["rank"] = 0


func _SnapBotStatValue(stat_id: String, value: float) -> float:
	var stat_data := GlobalBotStats.GetStatData(stat_id)
	var decimals := int(stat_data.get("decimals", 2))

	if decimals <= 0:
		return roundf(value)

	var step := pow(0.1, decimals)
	return snappedf(value, step)


func _MergeSingleBotStat(stat_id: String, value_a: float, value_b: float) -> float:
	var high = max(value_a, value_b)
	var low = min(value_a, value_b)

	# diminishing returns merge:
	# strongest stat stays, weaker contributes 50%
	var merged = high + low * 0.5
	return _SnapBotStatValue(stat_id, merged)


func _MergeOrderedBotStats(bot_a: Dictionary, bot_b: Dictionary) -> Dictionary:
	var ordered := _OrderMergeBots(bot_a, bot_b)
	var winner_stats = ordered["winner"].get("stats", {})
	var lower_stats = ordered["lower"].get("stats", {})
	return _MergeBotStatsDict(winner_stats, lower_stats)

func _OrderMergeBots(bot_a: Dictionary, bot_b: Dictionary) -> Dictionary:
	var score_a := _GetMergeBotStrengthScore(bot_a)
	var score_b := _GetMergeBotStrengthScore(bot_b)

	if score_b > score_a:
		return {
			"winner": bot_b,
			"lower": bot_a
		}

	if is_equal_approx(score_a, score_b):
		# deterministic tie-breaker so it never feels random
		var key_a := _BuildStableMergeTieKey(bot_a)
		var key_b := _BuildStableMergeTieKey(bot_b)

		if key_b < key_a:
			return {
				"winner": bot_b,
				"lower": bot_a
			}

	return {
		"winner": bot_a,
		"lower": bot_b
	}


func _GetMergeBotStrengthScore(bot_data: Dictionary) -> float:
	var score := 0.0
	var level := int(bot_data.get("level", 1))
	var rank := int(bot_data.get("rank", 0))
	var stats = bot_data.get("stats", {})

	# level should dominate if different levels can ever reach this point
	score += float(level) * 100000.0

	# rank is the next strongest signal
	score += float(rank) * 1000.0

	if typeof(stats) == TYPE_DICTIONARY:
		score += float(stats.size()) * 10.0

		for stat_id_value in stats.keys():
			var stat_id := str(stat_id_value)
			var value := float(stats[stat_id_value])
			score += _GetComparableMergeStatScore(stat_id, value)

	return score


func _GetComparableMergeStatScore(stat_id: String, value: float) -> float:
	var stat_data := GlobalBotStats.GetStatData(stat_id)
	if stat_data.is_empty():
		return absf(value)

	var stat_type := str(stat_data.get("stat_type", "percent"))
	var min_value := float(stat_data.get("min_value", 0.0))
	var max_value := float(stat_data.get("max_value", min_value))

	if stat_type == "flat":
		# flat stats are already stored as final rolled values on the bot
		return absf(value)

	if is_equal_approx(min_value, max_value):
		return absf(value)

	return clampf(inverse_lerp(min_value, max_value, value), 0.0, 1.0)


func _BuildStableMergeTieKey(bot_data: Dictionary) -> String:
	var stats = bot_data.get("stats", {})
	var parts: Array[String] = []

	if typeof(stats) == TYPE_DICTIONARY:
		var keys = stats.keys()
		keys.sort()

		for key_value in keys:
			var key := str(key_value)
			parts.append("%s:%0.4f" % [key, float(stats[key_value])])

	return "%04d|%04d|%s" % [
		int(bot_data.get("level", 1)),
		int(bot_data.get("rank", 0)),
		"|".join(parts)
	]
	
func _MergeBotStatsDict(stats_a: Dictionary, stats_b: Dictionary) -> Dictionary:
	var safe_a: Dictionary = stats_a if typeof(stats_a) == TYPE_DICTIONARY else {}
	var safe_b: Dictionary = stats_b if typeof(stats_b) == TYPE_DICTIONARY else {}

	if safe_a.is_empty() and safe_b.is_empty():
		return {}

	# If only one bot has stats, keep them.
	if safe_a.is_empty():
		return _CopySnappedBotStatsDict(safe_b)

	if safe_b.is_empty():
		return _CopySnappedBotStatsDict(safe_a)

	var inherit_ratio := 0.0
	if GlobalSkillTree != null \
	and typeof(GlobalSkillTree.skill_summary) == TYPE_DICTIONARY \
	and GlobalSkillTree.skill_summary.has("stats"):
		inherit_ratio = float(GlobalSkillTree.skill_summary.stats.get("merge_lower_bot_stat_inherit_ratio", 0.0))

	inherit_ratio = clampf(inherit_ratio, 0.0, 1.0)

	var score_a := _GetBotStatsDictStrengthScore(safe_a)
	var score_b := _GetBotStatsDictStrengthScore(safe_b)

	var winner_stats := safe_a
	var lower_stats := safe_b

	if score_b > score_a:
		winner_stats = safe_b
		lower_stats = safe_a

	var result := _CopySnappedBotStatsDict(winner_stats)

	if inherit_ratio <= 0.0:
		return result

	for stat_id_value in lower_stats.keys():
		var stat_id := str(stat_id_value)
		var lower_value := float(lower_stats[stat_id_value])

		if is_zero_approx(lower_value):
			continue

		var inherited_value := _SnapBotStatValue(stat_id, lower_value * inherit_ratio)
		if is_zero_approx(inherited_value):
			continue

		if result.has(stat_id):
			result[stat_id] = _SnapBotStatValue(
				stat_id,
				float(result[stat_id]) + inherited_value
			)
		else:
			result[stat_id] = inherited_value

	return result


func _CopySnappedBotStatsDict(stats_dict: Dictionary) -> Dictionary:
	var result := {}

	if typeof(stats_dict) != TYPE_DICTIONARY:
		return result

	for stat_id_value in stats_dict.keys():
		var stat_id := str(stat_id_value)
		result[stat_id] = _SnapBotStatValue(stat_id, float(stats_dict[stat_id_value]))

	return result


func _GetBotStatsDictStrengthScore(stats_dict: Dictionary) -> float:
	if typeof(stats_dict) != TYPE_DICTIONARY or stats_dict.is_empty():
		return 0.0

	var score := 0.0

	for stat_id_value in stats_dict.keys():
		var stat_id := str(stat_id_value)
		var value := float(stats_dict[stat_id_value])
		score += _GetComparableBotStatScore(stat_id, value)

	# tiny bias for more rolled stats
	score += float(stats_dict.size()) * 0.001

	return score


func _GetComparableBotStatScore(stat_id: String, value: float) -> float:
	var stat_data := GlobalBotStats.GetStatData(stat_id)
	if stat_data.is_empty():
		return absf(value)

	var stat_type := str(stat_data.get("stat_type", "percent"))
	var min_value := float(stat_data.get("min_value", 0.0))
	var max_value := float(stat_data.get("max_value", min_value))

	match stat_type:
		"flat":
			return absf(value)
		"percent", "multiplier":
			if is_equal_approx(min_value, max_value):
				return absf(value)
			return clampf(inverse_lerp(min_value, max_value, value), 0.0, 1.0)
		_:
			return absf(value)


func _GetMergedBotRank(rank_a: int, rank_b: int) -> int:
	# keep the better rarity for now
	return maxi(rank_a, rank_b)


func _ApplyMergedBotProgress(target_bot: Dictionary) -> void:
	target_bot.level = int(target_bot.level + 1)

	if target_bot.level == 3:
		if !GlobalSave.IsMilestoneCompleted("bot_level_3"):
			GlobalSave.SetMilestoneToCompleted("bot_level_3")

	if GlobalStats.HasChanceOfNextLevelBotOnMerge():
		target_bot.level += 1

	GlobalDailyQuest.RegisterMergeCreated(target_bot.level)
	GlobalSave.SetHighestBotLevel(target_bot.level)
