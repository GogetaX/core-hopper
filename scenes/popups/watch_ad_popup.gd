extends Control


func _ready() -> void:
	SyncData()
	SyncYSize()
	
func SyncData():
	var currency_data = GlobalBlockDatabase.GetAverageCoinsForDepth(GlobalSave.save_data.player_stats.max_depth_reached)
	print(currency_data)
	
func SyncYSize():
	if !is_node_ready():
		await ready
	await get_tree().process_frame
	var min_size_y = $SmartPanel/VBoxContainer.get_minimum_size().y
	custom_minimum_size.y = min_size_y+60
	size.y = custom_minimum_size.y
	$SmartPanel.position.y = (get_viewport_rect().size.y / 2.0)-(size.y / 2.0)

func _on_close_popup_btn_pressed() -> void:
	GlobalSignals.CloseCurPopup.emit()
