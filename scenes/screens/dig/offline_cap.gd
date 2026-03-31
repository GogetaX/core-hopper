extends Label

func _ready() -> void:
	GlobalSignals.DataSaved.connect(SyncData)
	SyncData()
	
func SyncData():
	var upgrade_value = GlobalOfflineProgress.GetOfflineCapSeconds()
	text = Global.SecondsToPrettyTimeString(upgrade_value)
