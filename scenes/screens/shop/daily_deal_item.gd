@tool
extends Control

@export_enum("WHITE","GOLD","PURPLE","BLUE","DISABLED","TAB_BG","ORANGE") var panel_color := "PURPLE":
	set(value):
		panel_color = value
		if is_node_ready():
			_ready()
	get:
		return panel_color

@export var deal_big_icon : Texture2D = null:
	set(value):
		deal_big_icon = value
		if is_node_ready():
			_ready()
	get:
		return deal_big_icon
		

@export var deal_small_icon : Texture2D = null:
	set(value):
		deal_small_icon = value
		if is_node_ready():
			_ready()
	get:
		return deal_small_icon

@export var deal_title : String = "Daily Crate":
	set(value):
		deal_title = value
		if is_node_ready():
			_ready()
	get:
		return deal_title
		
@export var deal_sub_title : String = "COMMON LOOT":
	set(value):
		deal_sub_title = value
		if is_node_ready():
			_ready()
	get:
		return deal_sub_title
		
@export var btn_value_txt : String = "FREE":
	set(value):
		btn_value_txt = value
		if is_node_ready():
			_ready()
	get:
		return btn_value_txt
			
func _ready() -> void:
	$SmartPanel/VBoxContainer/Control/IconBG.icon = deal_big_icon
	$SmartPanel/VBoxContainer/Control/IconBG.panel_color = panel_color
	$SmartPanel/VBoxContainer/BuyBtn.buy_btn_icon = deal_small_icon
	$SmartPanel/VBoxContainer/BuyBtn.buy_btn_title = btn_value_txt
	$SmartPanel/VBoxContainer/BuyBtn.panel_color = panel_color
	$SmartPanel/VBoxContainer/item_title.text = deal_title
	$SmartPanel/VBoxContainer/sub_title.text = deal_sub_title
