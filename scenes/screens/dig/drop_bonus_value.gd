extends Label

func _ready() -> void:
	GlobalSignals.DataSaved.connect(SyncData)
	SyncData()
	
func SyncData():
	var upgrade_value = GlobalStats.GetCoinYieldMultiplier()
	text = "x"+Global.FloatToStr(upgrade_value,0.01)
