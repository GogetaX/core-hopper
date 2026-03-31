@tool
extends Control

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
	var t = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	t.tween_property($SmartPanel,"scale",Vector2(0.9,0.9),0.05)
	t.tween_property($SmartPanel,"scale",Vector2(1.0,1.0),0.05)
	
