@tool
extends Node2D

class_name WorldSkillClass


var cur_skill_data = {}
var cur_skill_key = ""
var _is_selected = true


func GetSkillIcon():
	return $SmartPanelCircleSkill/TextureRect.texture
	
func InitSkill(skill_key,skill_data:Dictionary):
	cur_skill_data = skill_data
	cur_skill_key = skill_key
	global_position = Vector2(cur_skill_data.pos.x*2,cur_skill_data.pos.y*2)
	$SmartPanelCircleSkill/skill_name.text = cur_skill_data.title.to_upper()
	var skill_color_str = GlobalColor.GetSkillBranchColor(cur_skill_data.branch)
	$SmartPanelCircleSkill.panel_color = skill_color_str
	$SmartPanelCircleSkill/TextureRect.texture = GlobalSkillTree.GetIconFromStr(cur_skill_data.icon)
	$SmartPanelCircleSkill/TextureRect.self_modulate = $SmartPanelCircleSkill.GetBorderColor()
	$SmartPanelCircleSkill/skill_name.hash_tag_color = skill_color_str
	$SmartPanelCircleSkill/skill_level.hash_tag_color = skill_color_str
	var max_level = cur_skill_data.max_level
	var cur_level = GlobalSkillTree.GetAccuredSkillLevel(skill_key)
	$SmartPanelCircleSkill/skill_level.text = str(cur_level).pad_decimals(0)+"/"+str(max_level).pad_decimals(0)
	
	GlobalBtn.AddBtnPress($SmartPanelCircleSkill)
	GlobalBtn.BtnPress.connect(OnBtnPress)
	GlobalSignals.OnWorldSkillClassSelected.connect(OnSkillSelected)
	GlobalSignals.OnSkillLevelUpdated.connect(OnSkillUpdated)
	
	
	#Check visibility
	var skill_visible = true
	for x in cur_skill_data.prereq_ids:
		var prereq_skill_level = GlobalSkillTree.GetAccuredSkillLevel(x)
		if prereq_skill_level == 0:
			skill_visible = false
			break
	if !skill_visible:
		$SmartPanelCircleSkill.panel_color = "DISABLED"
		$SmartPanelCircleSkill.panel_type = "INSIDE_ONLY"
		$SmartPanelCircleSkill/TextureRect.self_modulate = GlobalColor.FromColorTextBorderToColor("WHITE")
		
	if Global.last_skill_key_selected == cur_skill_key:
		await get_tree().process_frame
		GlobalSignals.OnWorldSkillClassSelected.emit(self)
	else:
		AnimateOut()
	
func OnSkillUpdated(skill_id:String):
	#Check if its own skill, update level
	if cur_skill_key == skill_id:
		var max_level = cur_skill_data.max_level
		var cur_level = GlobalSkillTree.GetAccuredSkillLevel(skill_id)
		$SmartPanelCircleSkill/skill_level.text = str(cur_level).pad_decimals(0)+"/"+str(max_level).pad_decimals(0)
		GlobalSignals.OnWorldSkillClassSelected.emit(self)
		return
	#check if its prereq skills, update visibility if 0
	if !cur_skill_data.prereq_ids.is_empty() && cur_skill_data.prereq_ids.has(skill_id):
		var skill_color_str = GlobalColor.GetSkillBranchColor(cur_skill_data.branch)
		$SmartPanelCircleSkill.panel_color = skill_color_str
		$SmartPanelCircleSkill.panel_type = "BORDER_AND_INSIDE"
		$SmartPanelCircleSkill/TextureRect.self_modulate = $SmartPanelCircleSkill.GetBorderColor()
		return
		
func SetSelected(to_select:bool):
	_is_selected = to_select
	if _is_selected:
		AnimateOut()
	else:
		AnimateIn()
		
func IsSelected():
	return _is_selected

func OnSkillSelected(skill_node:WorldSkillClass):
	if skill_node != self:
		AnimateOut()
	else:
		Global.last_skill_key_selected = cur_skill_key
		AnimateIn()
func OnBtnPress(control_node:Control):
	if control_node != $SmartPanelCircleSkill:
		return
	GlobalSignals.OnWorldSkillClassSelected.emit(self)
	
func AnimateIn():
	if _is_selected:
		return
	
	_is_selected = true
	var t = create_tween()
	t.tween_property($SmartPanelCircleSkill,"modulate:a",1.0,0.2)
	$SmartPanelCircleSkill.AnimateShadow(true)
	
func AnimateOut():
	if !_is_selected:
		return
		
	_is_selected = false
	var t = create_tween()
	t.tween_property($SmartPanelCircleSkill,"modulate:a",0.3,0.2)
	$SmartPanelCircleSkill.AnimateShadow(false)
