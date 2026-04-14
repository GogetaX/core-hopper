extends Control

var cur_skill_state = "SELECTED_UP"

func _ready() -> void:
	GlobalSignals.OnWorldSkillClassSelected.connect(OnSkillClassSelected)
	_on_v_list_resized()
	SyncCurStateBtn()
	
func OnSkillClassSelected(skill_class:WorldSkillClass):
	var cur_skill_key = skill_class.cur_skill_key
	var cur_skill_data = GlobalSkillTree.GetSkillData(cur_skill_key)
	
	$SelectedSkill/VList/HList/VList/skill_name.text = cur_skill_data.title.to_upper()
	var cur_level = GlobalSkillTree.GetAccuredSkillLevel(cur_skill_key)
	var max_level = cur_skill_data.max_level
	$SelectedSkill/VList/HList/VList/skill_level.text = "LEVEL "+str(cur_level).pad_decimals(0)+" / "+str(max_level).pad_decimals(0)
	$SelectedSkill/VList/description.text = cur_skill_data.description
	$SelectedSkill/skill_icon.texture = skill_class.GetSkillIcon()
	$SelectedSkill/VList/HList/Control/HBoxContainer/IconBGCircle.icon = skill_class.GetSkillIcon()
	#Cur Level Effect
	if cur_level == 0:
		$SelectedSkill/VList/cur_level_row.visible = false
	else:
		$SelectedSkill/VList/cur_level_row.visible = true
	#Next level effect
	if cur_level < max_level:
		$SelectedSkill/VList/next_level_row.visible = true
		if cur_skill_data.effects.is_empty():
			$SelectedSkill/VList/next_level_row/next_level_effect.text = cur_skill_data.description
		else:
			$SelectedSkill/VList/cur_level_row/cur_level_effect.text = GlobalSkillTree.GetSkillCurrentEffectLine(cur_skill_key)
			$SelectedSkill/VList/next_level_row/next_level_effect.text = GlobalSkillTree.GetSkillNextEffectLine(cur_skill_key)
	else:
		$SelectedSkill/VList/cur_level_row/cur_level_effect.text = GlobalSkillTree.GetSkillCurrentEffectLine(cur_skill_key)
		$SelectedSkill/VList/next_level_row.visible = false
	#UpgradeSkillBtn rules
	$SelectedSkill/VList/UpgradeSkillBtn.visible = false
	if cur_level == 0 && cur_skill_data.effects.is_empty():
		var upgrade_pice = GlobalSkillTree.GetSkillNextCost(cur_skill_key)
		$SelectedSkill/VList/UpgradeSkillBtn.price_text = Global.CurrencyToString(upgrade_pice)
		$SelectedSkill/VList/UpgradeSkillBtn.price_int = upgrade_pice
		$SelectedSkill/VList/UpgradeSkillBtn.visible = true
	elif cur_level < max_level:
		if GlobalSkillTree.AreSkillPrereqsMet(cur_skill_key):
			var upgrade_pice = GlobalSkillTree.GetSkillNextCost(cur_skill_key)
			$SelectedSkill/VList/UpgradeSkillBtn.price_text = Global.CurrencyToString(upgrade_pice)
			$SelectedSkill/VList/UpgradeSkillBtn.price_int = upgrade_pice
			$SelectedSkill/VList/UpgradeSkillBtn.visible = true
	
	
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


func _on_v_list_resized() -> void:
	await get_tree().process_frame
	var max_y = $SelectedSkill/VList.get_minimum_size().y
	$SelectedSkill.custom_minimum_size.y = max_y +30
	$SelectedSkill.size.y = $SelectedSkill.custom_minimum_size.y
	#if cur_skill_state == "SELECTED_UP":
		#$SelectedSkill.position.y = get_viewport_rect().size.y - $SelectedSkill.size.y-350
	if cur_skill_state == "SELECTED_DOWN":
		cur_skill_state = "SELECTED_UP"
	SyncCurStateBtn()
	AnimateBasedOnState()

func _on_upgrade_skill_btn_btn_pressed_with_price(_currency: String, _price: int) -> void:
	var cur_selected_skill = Global.last_skill_key_selected
	if cur_selected_skill == "":
		return
	GlobalSkillTree.AccureSkill(cur_selected_skill)
	GlobalSignals.OnSkillLevelUpdated.emit(cur_selected_skill)
	var skill_data = GlobalSkillTree.GetSkillData(Global.last_skill_key_selected)
	if !skill_data.is_empty() && skill_data.has("effects"):
		for x in skill_data.effects:
			if x.has("stat"):
				match x.stat:
					"daily_free_mythic_bot_limit_bonus":
						GlobalSave.save_data.daily_free_bot.mythic_amount += 1
					"daily_free_bot_level_bonus":
						GlobalSave.save_data.daily_free_bot.amount += 1
	GlobalSave.SyncSave()


func _on_toggle_visibility_btn_toggled(_is_toggled: bool) -> void:
	GlobalSignals.OnShowAllSkillsToggled.emit(_is_toggled)
	if _is_toggled:
		GlobalSignals.ResetSkillCamera.emit()
