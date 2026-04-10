extends Node

@onready var merge_container = $"../MergePanel/MergeContainer"

func _ready() -> void:
	get_parent().ready.connect(OnParentReady)

func OnParentReady():
	GlobalSignals.DataSaved.connect(SyncAutoMerge)
	SyncAutoMerge()
	
func SyncAutoMerge():
	var active_merge = GlobalTimedBonus.GetActivatedBoosterIds()
	if active_merge.has("auto_merge"):
		await get_tree().create_timer(0.2).timeout
		var bot_list_to_level = {}
		#Get Minimum and max level
		for x in GlobalSave.save_data.bot_inventory.bot_db:
			if x.merge_slot_id != -1:
				if !bot_list_to_level.has(int(x.level)):
					bot_list_to_level[int(x.level)] = [x.uid]
				else:
					bot_list_to_level[int(x.level)].append(x.uid)
					
		var had_combination = false
		for bot_level in bot_list_to_level:
			if bot_list_to_level[bot_level].size()>=2:
				var bot_uid_1 = bot_list_to_level[bot_level][0]
				var bot_uid_2 = bot_list_to_level[bot_level][1]
				GlobalSave.CombineBetween2MergeNodes(bot_uid_2,bot_uid_1)
				had_combination = true
		
		if had_combination:
			GlobalSave.SyncSave()
		
	
