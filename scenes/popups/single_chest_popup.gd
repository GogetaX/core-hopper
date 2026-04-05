extends Control

func InitChest(data:Dictionary):
	print(data)


func _on_return_back_btn_pressed() -> void:
	#GlobalSignals.CloseCurPopup.emit()
	GlobalSignals.ShowPopup.emit("SHOW_CHESTS",{})
