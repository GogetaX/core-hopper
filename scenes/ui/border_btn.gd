@tool
extends Panel

@export var img : Texture2D = null:
	set(value):
		img = value
		if is_node_ready():
			_ready()
	get:
		return img
		
func _ready() -> void:
	$TextureRect.texture = img
