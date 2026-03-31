extends Label


func _ready() -> void:
	GlobalSignals.DataSaved.connect(SyncData)
	SyncData()
	
func SyncData():

	text = Global.CurrencyToString(GlobalSave.save_data.progress.global_depth)
