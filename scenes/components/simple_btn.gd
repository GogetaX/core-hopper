@tool
extends Control
signal OnPressed()

@export var title := "COLLECT NORMAL":
	set(value):
		title = value
		if is_node_ready():
			_ready()
	get:
		return title

func _ready() -> void:
	$SmartPanel/title.text = title
	if !Engine.is_editor_hint():
		GlobalBtn.AddBtnPress(self)
		GlobalBtn.BtnPress.connect(OnBtnPressed)
		GlobalBtn.AddBtnMouseInOut(self,[$SmartPanel])

func OnBtnPressed(btn_node:Control):
	if btn_node != self:
		return
	GlobalBtn.AnimateBtnPressed($SmartPanel)
	OnPressed.emit()
