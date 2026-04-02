extends Label
func _ready() -> void:
	GlobalSignals.DataSaved.connect(SyncData)
	SyncData()
	
func SyncData():
	var speed_value = 0.0
	for x in GlobalSave.save_data.bot_inventory.bot_db:
		if x.merge_slot_id == -1:
			speed_value += GlobalStats.GetBotFinalDigSpeedWithGlobal(x.level)
		else:
			speed_value += GlobalStats.GetBotFinalDigSpeed(x.level)
		
	text = "x"+str(snapped(speed_value,0.01))
	
