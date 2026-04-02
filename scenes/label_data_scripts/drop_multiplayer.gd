extends Label
func _ready() -> void:
	GlobalSignals.DataSaved.connect(SyncData)
	SyncData()
	
func SyncData():
	text = "x"+str(snapped(GlobalStats.GetGlobalCoinYieldMultiplayer(),0.01))
