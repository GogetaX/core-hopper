@tool
extends Control

signal BtnPressed()

@export var btn_text := "":
	set(value):
		btn_text = value
		if is_node_ready():
			_ready()
	get:
		return btn_text

@export var btn_icon : Texture2D = null:
	set(value):
		btn_icon = value
		if is_node_ready():
			_ready()
	get:
		return btn_icon
		
@export_enum("BLUE_MARGIN","PURPLE_MARGIN","GOLD_MARGIN","WHITE_MARGIN") var button_color := "BLUE_MARGIN":
	set(value):
		button_color = value
		if is_node_ready():
			_ready()
	get:
		return button_color

func _ready() -> void:
	$Panel/HBoxContainer/Label.text = btn_text
	$Panel/HBoxContainer/TextureRect.texture = btn_icon
	match button_color:
		"BLUE_MARGIN":
			$Panel.theme_type_variation = "PanelBlueBorder"
			$Panel/HBoxContainer.modulate = Color("D1FAFF")
		"PURPLE_MARGIN":
			$Panel.theme_type_variation = "PanelPurpleBorder"
			$Panel/HBoxContainer.modulate = Color("F2D6FF")
		"GOLD_MARGIN":
			$Panel.theme_type_variation = "PanelGoldBorder"
			$Panel/HBoxContainer.modulate = Color("FFE7A8")
		"WHITE_MARGIN":
			$Panel.theme_type_variation = "PanelDimmedBG"
			$Panel/HBoxContainer.modulate = Color.WHITE
	if !Engine.is_editor_hint():
		GlobalBtn.AddBtnPress(self)
		GlobalBtn.BtnPress.connect(OnBtnPress)
		mouse_entered.connect(OnMouseEntered)
		mouse_exited.connect(OnMouseExited)

func OnMouseExited():
	var t = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	t.tween_property($Panel,"modulate",Color.WHITE,0.05)
	
func OnMouseEntered():
	var t = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	t.tween_property($Panel,"modulate",Color.GRAY,0.05)
	
func OnBtnPress(btn_node:Control):
	if btn_node != self:
		return
	var t = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	t.tween_property($Panel,"scale",Vector2(0.9,0.9),0.05)
	t.tween_property($Panel,"scale",Vector2(1.0,1.0),0.05)
	BtnPressed.emit()
