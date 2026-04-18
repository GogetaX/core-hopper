extends MarginContainer

const SAFE_AREA = 1500

func _ready() -> void:
	_on_resized()
	
func _on_resized() -> void:
	var screen_size = DisplayServer.window_get_size()
	if screen_size.x > SAFE_AREA:
		var mergin_x = screen_size.x - SAFE_AREA
		offset_left = int(mergin_x / 2.0)
		offset_right = -int(mergin_x / 2.0)
