extends Label

func _ready() -> void:
	GlobalSignals.DataSaved.connect(SyncData)
	SyncData()
	
func SyncData():
	var upgrade_value = GlobalStats.GetUpgradeValue("coin_yield")
	text = "x"+Global.FloatToStr(upgrade_value,0.01)
