extends Control


func _on_v_box_container_resized() -> void:
	var max_y = $SmartPanel/VBoxContainer.get_minimum_size().y
	custom_minimum_size.y = max_y + 35
	await get_tree().process_frame
	size.y = custom_minimum_size.y
