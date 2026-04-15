extends Panel

func _ready() -> void:
	GlobalSignals.DataSaved.connect(OnSyncSave)
	OnSyncSave()
	
func OnSyncSave():
	HideAllProgress()
	var progress_data = GlobalCoreResetDb.GetProgressToNextReset()
	print(progress_data)
	if !progress_data.is_maxed:
		$CoreResetInProgress.visible = true
		$CoreResetInProgress/core_reset_progressbar.value = progress_data.progress*100.0
		$CoreResetInProgress/HList/core_recent_percent.text = str(snapped(progress_data.progress*100,1)).pad_decimals(0)
		
func HideAllProgress():
	for x in get_children():
		x.visible = false
