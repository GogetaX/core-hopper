extends Node

func _ready() -> void:
	get_parent().ready.connect(OnParentReady)
	
func OnParentReady():
	GlobalSignals.DataSaved.connect(SyncData)
	SyncData()
	
func SyncData():
	var tot_quest = GlobalStats.GetAdditionalDailyQuestLimit()+GlobalDailyQuest.DEFAULT_DAILY_COUNT
	get_parent().hash_tag_text = str(tot_quest).pad_decimals(0)+" DAILY QUESTS"
