@tool
extends Control

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
		
@export var hash_tag_text := "Text here":
	set(value):
		hash_tag_text = value
		if is_node_ready():
			_ready()
	get:
		return hash_tag_text

@export var hashtag_icon : Texture2D = null:
	set(value):
		hashtag_icon = value
		if is_node_ready():
			_ready()
	get:
		return hashtag_icon
		
@export var hide_bg := false:
	set(value):
		hide_bg = value
		if is_node_ready():
			_ready()
	get:
		return hide_bg
		
@export_enum("LEFT","MIDDLE","RIGHT") var text_direction := "LEFT":
	set(value):
		text_direction = value
		if is_node_ready():
			_ready()
	get:
		return text_direction
@export var is_currency := false
		

func _ready() -> void:
	$SmartPanel.panel_color = hash_tag_color
	$SmartPanel.panel_type = hash_tag_type
	#$HBoxContainer.modulate = $SmartPanel.GetTextColor()
	$HBoxContainer/ProgressHashTag.text = hash_tag_text
	$HBoxContainer/Control/TextureRect.texture = hashtag_icon
	$SmartPanel.visible = !hide_bg
	match text_direction:
		"LEFT":
			$HBoxContainer.alignment = 0
		"MIDDLE":
			$HBoxContainer.alignment = 1
		"RIGHT":
			$HBoxContainer.alignment = 2
			
func SyncMinXSize():
	if hide_bg:
		return
	var min_size := Vector2.ZERO
	min_size.x = $HBoxContainer.get_minimum_size().x
	min_size.y = $HBoxContainer/ProgressHashTag.get_minimum_size().y
	custom_minimum_size = Vector2(min_size.x+20,min_size.y)
	size = min_size
	
func _on_progress_hash_tag_resized() -> void:
	SyncMinXSize()
