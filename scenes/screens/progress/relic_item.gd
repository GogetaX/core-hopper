@tool
extends Control

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
		
@export var relic_name := "Relic Name":
	set(value):
		relic_name = value
		if is_node_ready():
			_ready()
	get:
		return relic_name
@export var relic_stat := "+10% power":
	set(value):
		relic_stat = value
		if is_node_ready():
			_ready()
	get:
		return relic_stat
func _ready() -> void:
	$SmartPanel/VBoxContainer/Control/IconBGCircle.panel_color = panel_color
	$SmartPanel/VBoxContainer/ProgressHashTag.hash_tag_color = panel_color
	$SmartPanel/VBoxContainer/Control/IconBGCircle.icon = icon
	$SmartPanel/VBoxContainer/relic_name.text = relic_name
	$SmartPanel/VBoxContainer/ProgressHashTag.text = relic_stat
