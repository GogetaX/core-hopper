@tool
extends Control
class_name ExpandRowButtonClass
signal OnPress()

@export_enum("PURPLE","ORANGE","BLUE","GOLD") var button_color = "PURPLE":
	set(value):
		button_color = value
		if is_node_ready():
			_ready()
	get:
		return button_color 

@export var btn_text := "button text":
	set(value):
		btn_text = value
		if is_node_ready():
			_ready()
	get:
		return btn_text
		
func _ready() -> void:
	$SmartPanel/ProgressHashTag.text = btn_text
	$SmartPanel.panel_color = button_color
	$SmartPanel/ProgressHashTag.hash_tag_color = button_color
	if !Engine.is_editor_hint():
		GlobalBtn.AddBtnPress(self)
		GlobalBtn.AddBtnMouseInOut(self,[$SmartPanel])
		GlobalBtn.BtnPress.connect(OnBtnPressed)
	
	
func OnBtnPressed(btn_node:Control):
	if btn_node != self:
		return
	GlobalBtn.AnimateBtnPressed($SmartPanel)
	OnPress.emit()
	
