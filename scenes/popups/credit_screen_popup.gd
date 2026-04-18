extends Control


func _on_close_btn_on_pressed() -> void:
	GlobalMusic.SFX_UIBack()
	GlobalSignals.CloseCurPopup.emit()


func _on_v_box_container_resized() -> void:
	var max_y = $SmartPanel/VList.get_minimum_size().y
	var max_y_rich = $SmartPanel/VList/Scroll/RichTextLabel.get_minimum_size().y
	custom_minimum_size.y = max_y + 40+max_y_rich
	await get_tree().process_frame
	size.y = custom_minimum_size.y
