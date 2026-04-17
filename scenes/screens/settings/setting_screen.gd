extends VBoxContainer

func _ready() -> void:
	GlobalCrazyGames.gameplay_stop()
	GlobalSignals.DataSaved.connect(SyncData)
	SyncData()
	$game_build_version.text = Global.GenerateGameVersion()
	
func SyncData():
	var settings = GlobalSave.save_data.settings
	$MusicToggleBtn.SetSelected(settings.music_enabled)
	$SFXToggleBtn.SetSelected(settings.sfx_enabled)
	$HapticToggleBtn.SetSelected(settings.vibration_enabled)
	


func _on_music_toggle_btn_is_toggled(toggled_on: bool) -> void:
	GlobalSave.save_data.settings["music_enabled"] = toggled_on
	GlobalSave.SyncSave()
	


func _on_sfx_toggle_btn_is_toggled(toggled_on: bool) -> void:
	GlobalSave.save_data.settings["sfx_enabled"] = toggled_on
	GlobalSave.SyncSave()


func _on_haptic_toggle_btn_is_toggled(toggled_on: bool) -> void:
	GlobalSave.save_data.settings["vibration_enabled"] = toggled_on
	GlobalSave.SyncSave()


func _on_expand_to_right_button_on_press() -> void:
	GlobalSignals.ShowPopup.emit("CREDIT_SCREEN",{})
