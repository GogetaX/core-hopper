@tool
extends Control
class_name StatusLabelClass

@export_enum("WHITE","GOLD","PURPLE","BLUE","DISABLED","TAB_BG","ORANGE") var panel_color := "PURPLE":
	set(value):
		panel_color = value
		if is_node_ready():
			_ready()
	get:
		return panel_color

@export var status_text := "DIGGING INACTIVE":
	set(value):
		status_text = value
		if is_node_ready():
			_ready()
			
	get:
		return status_text
		
func _ready() -> void:
	$SmartPanel.panel_color = panel_color
	$ProgressHashTag.hash_tag_color = panel_color
	$ProgressHashTag.text = status_text
	Resize()

func Resize():
	if !is_node_ready():
		return
	var max_x = $ProgressHashTag.get_minimum_size().x
	var max_y = 35
	custom_minimum_size.x = max_x+20
	custom_minimum_size.y = max_y
	size = custom_minimum_size
