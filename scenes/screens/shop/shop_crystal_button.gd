@tool
extends Control

@export_enum("WHITE","GOLD","PURPLE","BLUE","DISABLED","TAB_BG","ORANGE") var panel_color := "PURPLE":
	set(value):
		panel_color = value
		if is_node_ready():
			_ready()
	get:
		return panel_color
		
@export var item_name := "Handful of Gems":
	set(value):
		item_name = value
		if is_node_ready():
			_ready()
	get:
		return item_name

@export var item_subname := "500 Crystals + 50 Bonus":
	set(value):
		item_subname = value
		if is_node_ready():
			_ready()
	get:
		return item_subname
		
@export var item_price := "$1.99":
	set(value):
		item_price = value
		if is_node_ready():
			_ready()
	get:
		return item_price
		
@export var show_most_popular := false:
	set(value):
		show_most_popular = value
		if is_node_ready():
			_ready()
	get:
		return show_most_popular
		
@export var crystal_icon : Texture2D = null:
	set(value):
		crystal_icon = value
		if is_node_ready():
			_ready()
	get:
		return crystal_icon
		
func _ready() -> void:
	$SmartPanel/HList/IconBG.panel_color = panel_color
	$SmartPanel/HList/BuyBtn.panel_color = panel_color
	$SmartPanel/HList/VList/item_title.text = item_name
	$SmartPanel/HList/VList/item_subtitle.text = item_subname
	$SmartPanel/HList/BuyBtn.buy_btn_title = item_price
	$MostPopular.visible = show_most_popular
	$SmartPanel.panel_color = panel_color
	$SmartPanel/HList/IconBG.icon = crystal_icon
