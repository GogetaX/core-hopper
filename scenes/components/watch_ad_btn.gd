@tool
extends Control

signal OnAdGained()

@export var title := "CLAIM X2 REWARDS":
	set(value):
		title = value
		if is_node_ready():
			_ready()
	get:
		return title
@export var subtitle := "WATCH AD":
	set(value):
		subtitle = value
		if is_node_ready():
			_ready()
	get:
		return subtitle
func _ready() -> void:
	$SmartPanel/HList/VList/title_label.text = title
	$SmartPanel/HList/VList/subtitle_label.text = subtitle
	if !Engine.is_editor_hint():
		GlobalBtn.AddBtnPress(self)
		GlobalBtn.BtnPress.connect(OnBtnPressed)
		GlobalBtn.AddBtnMouseInOut(self,[$SmartPanel])

func OnBtnPressed(btn_node:Control):
	if btn_node != self:
		return
	GlobalBtn.AnimateBtnPressed($SmartPanel)
	OnAdGained.emit()
