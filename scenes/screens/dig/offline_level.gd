extends Label

func _ready() -> void:
	GlobalSignals.DataSaved.connect(SyncData)
	SyncData()
	
func SyncData():
	var upgrade_data = GlobalSave.save_data.upgrades.offline_efficiency
	text = upgrade_data.title +" lvl "+str(int(upgrade_data.level))
	
	
