extends Label

@export var end_text = ""
func _ready() -> void:
	GlobalSignals.DataSaved.connect(SyncData)
	SyncData()
	
func SyncData():
	var dps_value = 0.0
	for x in GlobalSave.save_data.bot_inventory.bot_db:
		dps_value += GlobalStats.GetBotFinalDPSWithGlobalAndStats(x)
		
	text = Global.CurrencyToString(int(dps_value)) + end_text
	
