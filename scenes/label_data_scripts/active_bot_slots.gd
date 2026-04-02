extends Label

const MAX_SLOTS = 16

func _ready() -> void:
	GlobalSignals.DataSaved.connect(SyncData)
	SyncData()
	
func SyncData():
	var active_merge_slots = GlobalSave.save_data.bot_inventory.merge_free_slots
	text = str(active_merge_slots).pad_decimals(0)+"/"+str(MAX_SLOTS).pad_decimals(0)
