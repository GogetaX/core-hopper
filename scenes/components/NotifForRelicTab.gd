extends Node

func _ready() -> void:
	GlobalSignals.DataSaved.connect(SyncData)
	get_parent().ready.connect(OnParentReady)
	
func OnParentReady():
	SyncData()
	
func SyncData():
	var relics_all = GlobalRelicDb.GetRelicInventory()
	var relic_unlocked_slots = relics_all.unlocked_slots
	var relic_equiped_slots = relics_all.equipped_ids
	
	#print(upgrade_list)
	var notif_counter = 0
	notif_counter = relic_unlocked_slots - relic_equiped_slots.size()
	get_parent().SetNotifCounter(notif_counter)
