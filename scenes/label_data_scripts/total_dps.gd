extends Label

@export var end_text = ""
func _ready() -> void:
	GlobalSignals.DataSaved.connect(SyncData)
	SyncData()
	
func SyncData():
	var dps_value = 0.0
	for x in GlobalSave.save_data.bot_inventory.bot_db:
		if x.merge_slot_id == -1:
			dps_value += GlobalStats.GetBotFinalDPSWithGobal(x.level)
		else:
			dps_value += GlobalStats.GetBotFinalDps(x.level)
		
	text = Global.CurrencyToString(dps_value) + end_text
	
