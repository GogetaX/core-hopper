extends VBoxContainer

func _on_view_quests_btn_btn_pressed() -> void:
	Global.progress_menu_show_tab = "QUESTS"
	GlobalSignals.OpenTabFromStr.emit("PROGRESS")


func _on_show_chests_btn_btn_pressed() -> void:
	GlobalSignals.ShowPopup.emit("SHOW_CHESTS",{})


func _on_watch_ad_btn_btn_pressed() -> void:
	GlobalSignals.ShowPopup.emit("WATCH_AD_POPUP",{})
