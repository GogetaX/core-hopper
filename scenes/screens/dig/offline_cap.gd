extends Label

func _ready() -> void:
	GlobalSignals.DataSaved.connect(SyncData)
	SyncData()
	
func SyncData():
	var upgrade_value = GlobalStats.GetOfflineCapSeconds()
	text = Global.SecondsToPrettyTimeString(upgrade_value)
