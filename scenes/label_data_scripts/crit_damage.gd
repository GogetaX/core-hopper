extends Label
func _ready() -> void:
	GlobalSignals.DataSaved.connect(SyncData)
	SyncData()
	
func SyncData():
	text = "x"+str(snapped(GlobalStats.GetCritChance(),0.01))
