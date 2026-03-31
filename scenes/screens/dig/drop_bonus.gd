extends Label

func _ready() -> void:
	GlobalSignals.DataSaved.connect(SyncData)
	SyncData()
	
func SyncData():
	var upgrade_data = GlobalSave.save_data.upgrades.coin_yield
	text = upgrade_data.title +" lvl "+str(int(upgrade_data.level))
