extends Control

var reset_effect_item = preload("res://scenes/components/core_reset_item.tscn")

func _ready() -> void:
	var reset_data = GlobalCoreResetDb.GetProgressToNextReset()
	var reset_core_data = GlobalCoreResetDb.GetNextResetData()
	print(reset_data)
	GlobalSignals.OnResetAnimStep.connect(OnResetAnimStep)
	$SmartPanel/VBoxContainer/core_reset_title.text = reset_core_data.title
	$SmartPanel/VBoxContainer/next_reward_desc.text = reset_core_data.description
	$SmartPanel/VBoxContainer/SmartPanel/VList/ReadyContainer.visible = false
	$SmartPanel/VBoxContainer/SmartPanel/VList/NotReadyContainer.visible = false
	if reset_data.current_depth >= reset_data.required_depth:
		$SmartPanel/VBoxContainer/SmartPanel/VList/ReadyContainer.visible = true
		$SmartPanel/VBoxContainer/CoreResetBtn.SetDisabled(false)
	else:
		$SmartPanel/VBoxContainer/SmartPanel/VList/NotReadyContainer.visible = true
		$SmartPanel/VBoxContainer/CoreResetBtn.SetDisabled(true)
	$SmartPanel/VBoxContainer/SmartPanel/VList/HList/target_value.text = "TARGET: "+str(reset_data.required_depth).pad_decimals(0)+"m"
	$SmartPanel/VBoxContainer/SmartPanel/VList/HList/current_best.text = "CURRENT BEST: "+str(GlobalSave.save_data.player_stats.max_depth_reached).pad_decimals(0)+"m"
	
	$SmartPanel/VBoxContainer/SmartPanel/VList/ProgressBar.value = reset_data.progress
	
	#clear old bonuses
	for x in $SmartPanel/VBoxContainer/BonusList.get_children():
		x.queue_free()
	for x in reset_core_data.effects:
		var i = reset_effect_item.instantiate() as CoreResetItemClass
		$SmartPanel/VBoxContainer/BonusList.add_child(i)
		i.InitItem(x)
	
func _on_close_popup_btn_pressed() -> void:
	GlobalSignals.CloseCurPopup.emit()


func _on_core_reset_btn_on_pressed() -> void:
	#Disable Mouse Press
	GlobalSignals.StopScreenClick.emit(true)
	
	#Core Reset and Save
	GlobalCoreResetDb.ActivateCoreReset()
	
	#Play Animation
	GlobalSignals.StartResetAnim.emit()
	#Hide everything, dig screen should be shown
	pass

func OnResetAnimStep(step_str):
	match step_str:
		"WHITE_BG":
			GlobalSignals.CloseCurPopup.emit()
		"RESET_FINISHED":
			pass
		_:
			print_debug("Reset Uknown step: ",step_str)
