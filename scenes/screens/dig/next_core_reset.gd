extends Control

func _ready() -> void:
	GlobalSignals.DataSaved.connect(OnSyncSave)
	GlobalBtn.AddBtnPress(self)
	GlobalBtn.BtnPress.connect(OnResetPress)
	OnSyncSave()
	
func OnResetPress(btn_node:Control):
	if btn_node != self:
		return
	GlobalBtn.AnimateBtnPressed(self)
	GlobalSignals.ShowPopup.emit("SHOW_CORE_RESET",{})
func OnSyncSave():
	HideAllProgress()
	var progress_data = GlobalCoreResetDb.GetProgressToNextReset()
	var reward_data = GlobalCoreResetDb.GetNextResetBonusStr("\n",false)
	if !progress_data.is_maxed:
		$CoreResetInProgress.visible = true
		$CoreResetInProgress/core_reset_progressbar.value = progress_data.progress*100.0
		$CoreResetInProgress/HList/core_recent_percent.text = str(snapped(progress_data.progress*100,1)).pad_decimals(0)
		
		$CoreResetInProgress/core_reset_reward.text = reward_data
		
func HideAllProgress():
	for x in get_children():
		if x is VBoxContainer:
			x.visible = false


func _on_core_reset_in_progress_resized() -> void:
	var max_y = $CoreResetInProgress.get_minimum_size().y
	custom_minimum_size.y = max_y + 40
	size.y = custom_minimum_size.y
