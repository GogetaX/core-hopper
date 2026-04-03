@tool
extends Control

signal OnPress()

@export var button_icon : Texture2D = null:
	set(value):
		button_icon = value
		if is_node_ready():
			_ready()
	get:
		return button_icon

@export var button_text := "Credits":
	set(value):
		button_text = value
		if is_node_ready():
			_ready()
	get:
		return button_text
		
func _ready() -> void:
	$SmartPanel2/HList/button_text.text = button_text
	$SmartPanel2/HList/button_icon.texture = button_icon
	if !Engine.is_editor_hint():
		GlobalBtn.AddBtnPress(self)
		GlobalBtn.AddBtnMouseInOut(self,[$SmartPanel2])
		GlobalBtn.BtnPress.connect(OnBtnPressed)
		
func OnBtnPressed(btn_node:Control):
	if btn_node != self:
		return
	GlobalBtn.AnimateBtnPressed($SmartPanel2)
	OnPress.emit()
	
