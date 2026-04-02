extends Label
func _ready() -> void:
	GlobalSignals.DataSaved.connect(SyncData)
	SyncData()
	
func SyncData():
	text = str(GlobalStats.GetCritMultiplier()).pad_decimals(0)+"% crit chance"
