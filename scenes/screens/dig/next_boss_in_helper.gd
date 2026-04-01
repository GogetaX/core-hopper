extends Node

func _ready() -> void:
	GlobalSignals.DataSaved.connect(SyncData)
	SyncData()
func SyncData():
	var glob_depth = GlobalSave.save_data.progress.global_depth
	var next_boss_depth = GlobalBossDb.GetNextBossDepth(glob_depth)
	get_parent().status_text = "BOSS BLOCK IN "+Global.CurrencyToString(next_boss_depth-glob_depth)+" M"
