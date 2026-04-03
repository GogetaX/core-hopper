@tool
extends Label

class_name HashtagClass

@export_enum("BORDER_ONLY","INSIDE_ONLY","BORDER_AND_INSIDE") var hash_tag_type = "BORDER_AND_INSIDE":
	set(value):
		hash_tag_type = value
		if is_node_ready():
			_ready()
	get:
		return hash_tag_type

@export_enum("WHITE","GOLD","PURPLE","BLUE","ORANGE","DISABLED") var hash_tag_color := "PURPLE":
	set(value):
		hash_tag_color = value
		if is_node_ready():
			_ready()
	get:
		return hash_tag_color
		
@export var no_bg := false:
	set(value):
		no_bg = value
		if is_node_ready():
			_ready()
	get:
		return no_bg

func _ready() -> void:
	$SmartPanel.set_border_as_bg = no_bg
	$SmartPanel.panel_color = hash_tag_color
	$SmartPanel.panel_type = hash_tag_type
	self_modulate = $SmartPanel.GetTextColor()
	$SmartPanel.visible = !no_bg
