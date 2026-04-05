extends Node

func _ready() -> void:
	GlobalSignals.DataSaved.connect(SyncData)
	get_parent().ready.connect(OnParentReady)
	
func OnParentReady():
	SyncData()
	
func SyncData():
	var quest_list = GlobalDailyQuest.GetAllActiveQuests()
	#print(upgrade_list)
	var notif_counter = 0
	for x in quest_list:
		if x.is_complete && !x.is_claimed:
			notif_counter += 1
	get_parent().SetNotifCounter(notif_counter)
