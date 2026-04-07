extends Node

func _ready() -> void:
	GlobalSignals.DataSaved.connect(SyncData)
	get_parent().ready.connect(OnParentReady)
	
func OnParentReady():
	SyncData()
	
func SyncData():
	var relics_all = GlobalRelicDb.GetRelicInventory()
	var unlocked_slots: int = relics_all.unlocked_slots
	var equipped_ids: Array = relics_all.equipped_ids
	var owned_count: int = relics_all.owned.size()

	var equipped_count := 0
	for relic_id in equipped_ids:
		if str(relic_id).strip_edges() != "":
			equipped_count += 1

	var empty_unlocked_slots = max(0, unlocked_slots - equipped_count)
	var unequipped_owned = max(0, owned_count - equipped_count)

	var notif_counter = min(empty_unlocked_slots, unequipped_owned)
	get_parent().SetNotifCounter(notif_counter)
