@tool
extends Control
signal OnPress()

@export var buy_btn_title := "NEW UNIT":
	set(value):
		buy_btn_title = value
		if is_node_ready():
			SyncTool()
	get:
		return buy_btn_title

@export_enum("WHITE","GOLD","PURPLE","BLUE","DISABLED","TAB_BG","ORANGE") var panel_color := "PURPLE":
	set(value):
		panel_color = value
		if is_node_ready():
			SyncTool()
	get:
		return panel_color
		
@export var buy_btn_icon : Texture2D = null:
	set(value):
		buy_btn_icon = value
		if is_node_ready():
			SyncTool()
	get:
		return buy_btn_icon


func _ready() -> void:
	SyncTool()
	if !Engine.is_editor_hint():
		GlobalBtn.AddBtnPress(self)
		GlobalBtn.AddBtnMouseInOut(self,[$Background])
		GlobalBtn.BtnPress.connect(OnBtnPressed)
		SyncTool()
		
func SyncTool():
	if !is_node_ready():
		await ready
			
	$Background/HList/Label.text = buy_btn_title
	$Background.panel_color = panel_color
	$Background/HList/icon.texture = buy_btn_icon
	$Background/HList/Label.self_modulate = $Background.GetBorderColor()
	$Background/HList/icon.self_modulate = $Background.GetBorderColor()
	
func ShowOnly(show_btn:Control):
	for x in get_children():
		if x != show_btn:
			x.visible = false
	show_btn.visible = true
	
func OnBtnPressed(btn_node:Control):
	if btn_node != self:
		return
	GlobalBtn.AnimateBtnPressed($Background)
	OnPress.emit()
	
func OnMergeBtnPressed(btn_node:Control):
	if btn_node != self:
		return
	GlobalBtn.AnimateBtnPressed($Background)
