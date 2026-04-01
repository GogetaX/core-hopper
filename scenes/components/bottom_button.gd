@tool
extends Control
class_name ButtonTabClass

@export var btn_name := "DIG":
	set(value):
		btn_name = value
		if is_node_ready():
			_ready()
	get:
		return btn_name
		
@export var belong_to_tab := "bottom_tab"
@export var is_default := false

var is_pressed = false
		
func _ready() -> void:
	$VList/Label.text = btn_name
	if !Engine.is_editor_hint():
		$Panel.self_modulate.a = 0.0
		GlobalBtn.AddBtnPress(self)
		GlobalBtn.BtnPress.connect(OnBtnPressed)
		GlobalSignals.OnTabBtnpressed.connect(OnTabPressed)
		GlobalSignals.OpenTabFromStr.connect(OnForceTabFromStr)
		if is_default:
			AnimatePressed()

func OnForceTabFromStr(tab_name:String):
	if btn_name == tab_name:
		AnimatePressed()
	else:
		AnimateUnpressed()
func OnTabPressed(btn_node:ButtonTabClass):
	if btn_node == self:
		AnimatePressed()
	elif btn_node.belong_to_tab == belong_to_tab:
		AnimateUnpressed()
		
func AnimatePressed():
	if is_pressed:
		return
	is_pressed = true
	var t =create_tween()
	t.tween_property($Panel,"self_modulate:a",1.0,0.1)
	
func AnimateUnpressed():
	if !is_pressed:
		return
	is_pressed = false
	var t =create_tween()
	t.tween_property($Panel,"self_modulate:a",0.0,0.1)
	
func OnBtnPressed(btn_node:Control):
	if btn_node != self:
		return
	GlobalSignals.OnTabBtnpressed.emit(self)
