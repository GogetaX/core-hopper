extends Node

func _ready() -> void:
	GlobalSignals.DataSaved.connect(SyncData)
	get_parent().ready.connect(OnParentReady)
	
func OnParentReady():
	SyncData()
	
func SyncData():
	var upgrade_list = GlobalSave.save_data.upgrades
	#print(upgrade_list)
	var notif_counter = 0
	var cur_currency = GlobalSave.GetCurrency("coins")
	for x in upgrade_list:
		if cur_currency >= GlobalStats.GetUpgradeCost(x):
			notif_counter += 1
	get_parent().SetNotifCounter(notif_counter)
