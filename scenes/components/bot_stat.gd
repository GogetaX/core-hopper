@tool
extends Control
class_name BotStatItemClass

@export_enum("WHITE","GOLD","PURPLE","BLUE","DISABLED","TAB_BG","ORANGE") var panel_color := "PURPLE":
	set(value):
		panel_color = value
		if is_node_ready():
			_ready()
	get:
		return panel_color

@export var icon : Texture2D = null:
	set(value):
		icon = value
		if is_node_ready():
			_ready()
	get:
		return icon
		
@export var top_value := "150K":
	set(value):
		top_value = value
		if is_node_ready():
			_ready()
	get:
		return top_value

@export var stat_name := "DPS":
	set(value):
		stat_name = value
		if is_node_ready():
			_ready()
	get:
		return stat_name

func _ready() -> void:
	$SmartPanel.panel_color = panel_color
	$SmartPanel/HBoxContainer/icon.texture = icon
	$SmartPanel/HBoxContainer/icon.self_modulate = $SmartPanel.GetTextColor()
	$SmartPanel/HBoxContainer/VBoxContainer/top_value.text = top_value
	$SmartPanel/HBoxContainer/VBoxContainer/stat_name.text = stat_name
	$SmartPanel/HBoxContainer/VBoxContainer/top_value.hash_tag_color = panel_color
	await get_tree().process_frame
	ResizeX()
	
func ResizeX():
	var size_x = $SmartPanel/HBoxContainer.get_minimum_size().x
	custom_minimum_size.x = size_x + 35
