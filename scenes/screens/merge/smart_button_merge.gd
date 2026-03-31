@tool
extends Control

@export_enum("BUY_BTN","MERGE_BTN") var btn_type := "BUY_BTN":
	set(value):
		btn_type = value
		if is_node_ready():
			_ready()
	get:
		return btn_type
		
@export var buy_btn_title := "NEW UNIT":
	set(value):
		buy_btn_title = value
		if is_node_ready():
			_ready()
	get:
		return buy_btn_title

@export var buy_btn_text := "BUY BOT":
	set(value):
		buy_btn_text = value
		if is_node_ready():
			_ready()
	get:
		return buy_btn_text
		
@export var buy_btn_icon :Texture2D:
	set(value):
		buy_btn_icon = value
		if is_node_ready():
			_ready()
	get:
		return buy_btn_icon
		
@export var merge_btn_text := "AUTO-MERGE":
	set(value):
		merge_btn_text = value
		if is_node_ready():
			_ready()
	get:
		return merge_btn_text

@export var merge_btn_sub_title := "SYSTEM COOLDOWN: 12S":
	set(value):
		merge_btn_sub_title = value
		if is_node_ready():
			_ready()
	get:
		return merge_btn_sub_title
		
@export var merge_btn_icon :Texture2D:
	set(value):
		merge_btn_icon = value
		if is_node_ready():
			_ready()
	get:
		return merge_btn_icon

func _ready() -> void:
	SetBtnType()
	if !Engine.is_editor_hint():
		GlobalBtn.AddBtnPress(self)
		

func SetBtnType():
	match btn_type:
		"BUY_BTN":
			ShowOnly($BuyBtn)
			$BuyBtn/HBoxContainer/VBoxContainer/label_title.text = buy_btn_title
			$BuyBtn/HBoxContainer/VBoxContainer/label_text.text = buy_btn_text
			$BuyBtn/HBoxContainer/icon.texture = buy_btn_icon
			if !Engine.is_editor_hint():
				GlobalBtn.AddBtnMouseInOut(self,[$BuyBtn])
				GlobalBtn.BtnPress.connect(OnBuyBtnPressed)
		"MERGE_BTN":
			ShowOnly($MergeBtn)
			$MergeBtn/HBoxContainer/VBoxContainer/label_text.text = merge_btn_text
			$MergeBtn/HBoxContainer/VBoxContainer/label_sub_title.text = merge_btn_sub_title
			$MergeBtn/HBoxContainer/icon.texture = merge_btn_icon
			if !Engine.is_editor_hint():
				GlobalBtn.AddBtnMouseInOut(self,[$MergeBtn])
				GlobalBtn.BtnPress.connect(OnMergeBtnPressed)
		_:
			print_debug("Unknown Btn type: ",btn_type)

func ShowOnly(show_btn:Control):
	for x in get_children():
		if x != show_btn:
			x.visible = false
	show_btn.visible = true
	
func OnBuyBtnPressed(btn_node:Control):
	if btn_node != self:
		return
	var t = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	t.tween_property($BuyBtn,"scale",Vector2(0.9,0.9),0.05)
	t.tween_property($BuyBtn,"scale",Vector2(1.0,1.0),0.05)
	
func OnMergeBtnPressed(btn_node:Control):
	if btn_node != self:
		return
	var t = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	t.tween_property($MergeBtn,"scale",Vector2(0.9,0.9),0.05)
	t.tween_property($MergeBtn,"scale",Vector2(1.0,1.0),0.05)
