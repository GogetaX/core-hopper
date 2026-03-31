@tool
extends Control

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
		
@export var text := "Join Discord":
	set(value):
		text = value
		if is_node_ready():
			_ready()
	get:
		return text
		
func _ready() -> void:
	$SmartPanel.panel_color = panel_color
	$SmartPanel/VList/TextureRect.texture = icon
	$SmartPanel/VList/TextureRect.self_modulate = $SmartPanel.GetBorderColor()
	$SmartPanel/VList/text.text = text
	if !Engine.is_editor_hint():
		GlobalBtn.AddBtnPress(self)
		GlobalBtn.AddBtnMouseInOut(self,[$SmartPanel])
		GlobalBtn.BtnPress.connect(OnBtnPressed)
func OnBtnPressed(btn_node:Control):
	if btn_node != self:
		return
	GlobalBtn.AnimateBtnPressed($SmartPanel)
