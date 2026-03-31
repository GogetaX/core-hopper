extends Control

var cur_skill_state = "SELECTED_UP"

func _ready() -> void:
	SyncCurStateBtn()
	
func SyncCurStateBtn():
	$SelectedSkill/VList/HList/Control/HBoxContainer/ScrollDownBtn.visible = false
	$SelectedSkill/VList/HList/Control/HBoxContainer/ScrollUpBtn.visible = false
	match cur_skill_state:
		"SELECTED_DOWN":
			$SelectedSkill/VList/HList/Control/HBoxContainer/ScrollUpBtn.visible = true
		"SELECTED_UP":
			$SelectedSkill/VList/HList/Control/HBoxContainer/ScrollDownBtn.visible = true
func _on_scroll_down_btn_btn_pressed() -> void:
	cur_skill_state = "SELECTED_DOWN"
	SyncCurStateBtn()
	AnimateBasedOnState()

func AnimateBasedOnState():
	match cur_skill_state:
		"SELECTED_DOWN":
			var t = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
			t.tween_property($SelectedSkill,"position:y",get_viewport_rect().size.y-480,0.3)
		"SELECTED_UP":
			var t = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
			t.tween_property($SelectedSkill,"position:y",get_viewport_rect().size.y-$SelectedSkill.size.y-350,0.3)


func _on_scroll_up_btn_btn_pressed() -> void:
	cur_skill_state = "SELECTED_UP"
	SyncCurStateBtn()
	AnimateBasedOnState()


func _on_reset_camera_btn_pressed() -> void:
	GlobalSignals.ResetSkillCamera.emit()


func _on_center_selected_skill_btn_pressed() -> void:
	GlobalSignals.CenterCameraCurSelectedSkill.emit()
