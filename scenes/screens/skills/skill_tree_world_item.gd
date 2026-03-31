@tool
extends Node2D

class_name WorldSkillClass

@export_enum("WHITE","GOLD","PURPLE","BLUE","DISABLED","TAB_BG","ORANGE") var panel_color := "PURPLE":
	set(value):
		panel_color = value
		if is_node_ready():
			_ready()
	get:
		return panel_color
		
@export var icon : Texture2D= null:
	set(value):
		icon = value
		if is_node_ready():
			_ready()
	get:
		return icon
		
@export var skill_name := "AUTO-COLLECTOR":
	set(value):
		skill_name = value
		if is_node_ready():
			_ready()
	get:
		return skill_name
		
@export var skill_visible := true:
	set(value):
		skill_visible = value
		if is_node_ready():
			_ready()
	get:
		return skill_visible
		

var _is_selected = true

func _ready() -> void:
	$SmartPanelCircleSkill.panel_color = panel_color
	$SmartPanelCircleSkill/TextureRect.texture = icon
	$SmartPanelCircleSkill/TextureRect.self_modulate = $SmartPanelCircleSkill.GetBorderColor()
	$SmartPanelCircleSkill/skill_name.text = skill_name
	$SmartPanelCircleSkill/skill_name.hash_tag_color = panel_color
	if !skill_visible:
		modulate.a = 0.1
	else:
		modulate.a = 1.0
		
	if !Engine.is_editor_hint():
		GlobalBtn.AddBtnPress($SmartPanelCircleSkill)
		GlobalBtn.BtnPress.connect(OnBtnPressed)
		GlobalSignals.OnWorldSkillClassSelected.connect(OnSelectedSkill)
		AnimateOut()
		if !skill_visible:
			visible = false

func IsSelected():
	return _is_selected
	
func OnSelectedSkill(skill_node:WorldSkillClass):
	if skill_node != self:
		AnimateOut()
	else:
		AnimateIn()
			
func OnBtnPressed(btn_node:Control):
	if btn_node != $SmartPanelCircleSkill:
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
	t.tween_property($SmartPanelCircleSkill,"modulate:a",0.5,0.2)
	$SmartPanelCircleSkill.AnimateShadow(false)
