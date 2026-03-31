@tool
extends Control

signal BtnPressed()

@export_enum("BORDER_ONLY","INSIDE_ONLY","BORDER_AND_INSIDE") var panel_type = "BORDER_AND_INSIDE":
	set(value):
		panel_type = value
		if is_node_ready():
			_ready()
	get:
		return panel_type
		
@export_enum("WHITE","GOLD","PURPLE","BLUE","DISABLED","TAB_BG","ORANGE") var panel_color := "PURPLE":
	set(value):
		panel_color = value
		if is_node_ready():
			_ready()
	get:
		return panel_color
		
		
@export var icon : Texture2D = null:
	set(value):
		icon = value
		if is_node_ready():
			_ready()
	get:
		return icon
		
@export var as_button := false
		
func _ready() -> void:
	$IconBG.panel_color = panel_color
	$IconBG.panel_type = panel_type
	$IconBG/SkillIcon.self_modulate = $IconBG.GetBorderColor()
	$IconBG/SkillIcon.texture = icon
	if !Engine.is_editor_hint():
		if as_button:
			GlobalBtn.AddBtnPress(self)
			GlobalBtn.BtnPress.connect(OnBtnPressed)
			GlobalBtn.AddBtnMouseInOut(self,[$IconBG])

func OnBtnPressed(btn_node:Control):
	if btn_node != self:
		return
	GlobalBtn.AnimateBtnPressed($IconBG)
	BtnPressed.emit()
	
func GetTextColor():
	return $IconBG.GetTextColor()

func GetBorderColor():
	return $IconBG.GetBorderColor()
