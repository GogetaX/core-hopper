@tool
extends Control

signal BtnPressed()
signal BtnToggled(_is_toggled:bool)

@export_enum("BORDER_ONLY","INSIDE_ONLY","BORDER_AND_INSIDE","NO_BG") var panel_type = "BORDER_AND_INSIDE":
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
		
@export_enum("AS_ICON","AS_BUTTON","AS_TOGGLE") var btn_type := "AS_ICON"

var is_toggled = false
func _ready() -> void:
	$IconBG.panel_color = panel_color
	$IconBG.panel_type = panel_type
	$IconBG/SkillIcon.self_modulate = $IconBG.GetBorderColor()
	$IconBG/SkillIcon.texture = icon
	if !Engine.is_editor_hint():
		if btn_type == "AS_BUTTON" || btn_type == "AS_TOGGLE":
			GlobalBtn.AddBtnPress(self)
			GlobalBtn.BtnPress.connect(OnBtnPressed)
			GlobalBtn.AddBtnMouseInOut(self,[$IconBG])

func OnBtnPressed(btn_node:Control):
	if btn_node != self:
		return
	GlobalBtn.AnimateBtnPressed($IconBG)
	match btn_type:
		"AS_BUTTON":
			BtnPressed.emit()
		"AS_TOGGLE":
			is_toggled = !is_toggled
			$IconBG.set_border_as_bg = is_toggled
			$IconBG/SkillIcon.self_modulate = $IconBG.GetBorderColor()
			BtnToggled.emit(is_toggled)
	
func GetTextColor():
	return $IconBG.GetTextColor()

func GetBorderColor():
	return $IconBG.GetBorderColor()
