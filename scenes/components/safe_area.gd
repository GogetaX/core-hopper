extends MarginContainer

func _ready() -> void:
	_on_resized()
	
func _on_resized() -> void:
	var screen_size = DisplayServer.window_get_size()
	if screen_size.x > 1500:
		var mergin_x = screen_size.x - 1500.0
		offset_left = int(mergin_x / 2.0)
		offset_right = -int(mergin_x / 2.0)
