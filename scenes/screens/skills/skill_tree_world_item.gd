extends Node2D

class_name WorldSkillClass

var cur_skill_key = ""
var _is_selected = false

var is_all_skill_toggled = false

func _ready() -> void:
	if !Engine.is_editor_hint():
		GlobalSignals.OnShowAllSkillsToggled.connect(OnShowAllSkillsToggled)
	
func OnShowAllSkillsToggled(is_toggled:bool):
	is_all_skill_toggled = is_toggled
	SetSkillVisibility()
	
func GetSkillIcon():
	return $SmartPanelCircleSkill/TextureRect.texture
	
func InitSkill(skill_key):
	
	var skill_data = GlobalSkillTree.GetSkillData(skill_key)
	cur_skill_key = skill_key
	global_position = Vector2(skill_data.pos.x*2,skill_data.pos.y*2)
	$SmartPanelCircleSkill/skill_name.text = skill_data.title.to_upper()
	var skill_color_str = GlobalSkillTree.GetBranchColorStr(skill_data.branch)
	$SmartPanelCircleSkill.panel_color = skill_color_str
	$SmartPanelCircleSkill/TextureRect.texture = GlobalSkillTree.GetIconFromStr(skill_data.icon)
	$SmartPanelCircleSkill/TextureRect.self_modulate = $SmartPanelCircleSkill.GetBorderColor()
	$SmartPanelCircleSkill/skill_name.hash_tag_color = skill_color_str
	$SmartPanelCircleSkill/skill_level.hash_tag_color = skill_color_str
	var max_level = skill_data.max_level
	var cur_level = GlobalSkillTree.GetAccuredSkillLevel(skill_key)
	$SmartPanelCircleSkill/skill_level.text = str(cur_level).pad_decimals(0)+"/"+str(max_level).pad_decimals(0)
	
	GlobalBtn.AddBtnPress($SmartPanelCircleSkill)
	GlobalBtn.BtnPress.connect(OnBtnPress)
	GlobalSignals.OnWorldSkillClassSelected.connect(OnSkillSelected)
	GlobalSignals.OnSkillLevelUpdated.connect(OnSkillUpdated)
	
	SetSkillVisibility()
	
	if Global.last_skill_key_selected == cur_skill_key:
		await get_tree().process_frame
		GlobalSignals.OnWorldSkillClassSelected.emit(self)
		
	

func SetSkillVisibility():
	$notif.visible = false
	#Check visibility
	var skill_data = GlobalSkillTree.GetSkillData(cur_skill_key)
	var cur_level = GlobalSkillTree.GetAccuredSkillLevel(cur_skill_key)
	var get_prereq = GlobalSkillTree.GetSkillPrereqIDs(cur_skill_key)
	var skill_color_str = GlobalSkillTree.GetBranchColorStr(skill_data.branch)
	var max_level = skill_data.max_level
	$SmartPanelCircleSkill/skill_level.text = str(cur_level).pad_decimals(0)+"/"+str(max_level).pad_decimals(0)
	
	
	$SmartPanelCircleSkill.panel_color = skill_color_str
	if cur_level == 0:
		$SmartPanelCircleSkill.panel_color = "DISABLED"
	if get_prereq.is_empty():
		if _is_selected:
			visible = true
			$SmartPanelCircleSkill.set_border_as_bg = true
			$SmartPanelCircleSkill/skill_level.visible = true
			$SmartPanelCircleSkill/skill_name.visible = true
			$SmartPanelCircleSkill.panel_type = "INSIDE_ONLY"
		else:
			visible = true
			$SmartPanelCircleSkill.panel_type = "BORDER_AND_INSIDE"
			$SmartPanelCircleSkill/skill_level.visible = false
			$SmartPanelCircleSkill/skill_name.visible = false
			$SmartPanelCircleSkill.set_border_as_bg = false
	else:
		var has_prepreq = false
		var prereq_amount = 0
		for x in get_prereq:
			if GlobalSkillTree.GetAccuredSkillLevel(x)>0:
				prereq_amount += 1

		if prereq_amount != get_prereq.size():
			has_prepreq = false
		else:
			has_prepreq = true
		
		if !has_prepreq:
			if !is_all_skill_toggled:
				visible = false
			else:
				if _is_selected:
					visible = true
					$SmartPanelCircleSkill.set_border_as_bg = true
					$SmartPanelCircleSkill/skill_level.visible = true
					$SmartPanelCircleSkill/skill_name.visible = true
					$SmartPanelCircleSkill.panel_type = "INSIDE_ONLY"
				else:
					visible = true
					$SmartPanelCircleSkill.set_border_as_bg = false
					$SmartPanelCircleSkill/skill_level.visible = true
					$SmartPanelCircleSkill/skill_name.visible = true
					$SmartPanelCircleSkill.panel_type = "BORDER_AND_INSIDE"
		else:
			if !visible:
				modulate.a = 0.0
				visible = true
				var t = create_tween()
				t.tween_property(self,"modulate:a",1.0,0.3)
				GlobalSignals.AddNotification.emit({"type":"TEXT","description":"Unlocked skill!\n"+skill_data.title,"color":"ORANGE"})
			if _is_selected:
				$SmartPanelCircleSkill.set_border_as_bg = true
				$SmartPanelCircleSkill/skill_level.visible = true
				$SmartPanelCircleSkill/skill_name.visible = true
				$SmartPanelCircleSkill.panel_type = "INSIDE_ONLY"
				z_index = 1
			else:
				$SmartPanelCircleSkill.set_border_as_bg = false
				$SmartPanelCircleSkill/skill_level.visible = false
				$SmartPanelCircleSkill/skill_name.visible = false
				$SmartPanelCircleSkill.panel_type = "BORDER_AND_INSIDE"
				z_index = 0
	
	if is_all_skill_toggled:
		$SmartPanelCircleSkill/skill_level.visible = true
		$SmartPanelCircleSkill/skill_name.visible = true
		if _is_selected:
			z_index = 1
		else:
			z_index = 0
	$SmartPanelCircleSkill/TextureRect.self_modulate = $SmartPanelCircleSkill.GetBorderColor()
	
	#Init Progress bar
	$SmartPanelCircleSkill/TextureProgressBar.max_value = max_level
	$SmartPanelCircleSkill/TextureProgressBar.value = cur_level
	$SmartPanelCircleSkill/TextureProgressBar.tint_under = $SmartPanelCircleSkill.GetBorderColor()
	$SmartPanelCircleSkill/TextureProgressBar.tint_progress = $SmartPanelCircleSkill.GetTextColor()
	
	#Set Notification
	if !_is_selected:
		var has_prepreq = false
		var prereq_amount = 0
		for x in get_prereq:
			if GlobalSkillTree.GetAccuredSkillLevel(x)>0:
				prereq_amount += 1

		if prereq_amount != get_prereq.size():
			has_prepreq = false
		else:
			has_prepreq = true
		if cur_level < max_level && has_prepreq:
			if GlobalSkillTree.GetSkillNextCost(cur_skill_key) <= GlobalSave.GetCurrency("crystals"):
				$notif.visible = true
	
func OnSkillUpdated(_skill_id:String):
	if _skill_id == cur_skill_key:
		SetSelected(true)
		GlobalSignals.OnWorldSkillClassSelected.emit(self)
	else:
		SetSelected(false)
		
func SetSelected(to_select:bool):
	_is_selected = to_select
	SetSkillVisibility()
	


func IsSelected():
	return _is_selected

func OnSkillSelected(skill_node:WorldSkillClass):
	if skill_node != self:
		SetSelected(false)
	else:
		Global.last_skill_key_selected = cur_skill_key
		SetSelected(true)
		
func OnBtnPress(control_node:Control):
	if control_node != $SmartPanelCircleSkill:
		return
	GlobalSignals.OnWorldSkillClassSelected.emit(self)
