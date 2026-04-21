extends Control
class_name OfflineBandSelectorClass

var cur_data = {}

func _ready() -> void:
	GlobalSignals.SelectedOfflineBandSync.connect(OnSelectedBandIndex)
	
func OnSelectedBandIndex(band_index:int):
	if band_index != cur_data.band_index:
		$SmartPanel/HBoxContainer/HList/SettingToggle.SetEnabled(false)
		
func InitBandData(data:Dictionary):
	cur_data = data

	$SmartPanel/HBoxContainer/VList/HBoxContainer/meter_value.text = str(cur_data.min_depth).pad_decimals(0)+"-"+str(cur_data.max_depth).pad_decimals(0)+"m"
	$SmartPanel/HBoxContainer/VList/HBoxContainer/recomendation_hint.text = cur_data.title.to_upper()
	$SmartPanel/HBoxContainer/HList/SettingToggle.SetEnabled(cur_data.is_selected)
	match cur_data.slot:
		"easy_coins":
			$SmartPanel/HBoxContainer/IconBG.panel_color = "GOLD"
			$SmartPanel/HBoxContainer/VList/ProgressBar.theme_type_variation = "ProgressBarGold"
			$SmartPanel/HBoxContainer/VList/HBoxContainer/recomendation_hint.hash_tag_color = "GOLD"
		"recommended":
			$SmartPanel/HBoxContainer/IconBG.panel_color = "BLUE"
			$SmartPanel/HBoxContainer/VList/ProgressBar.theme_type_variation = "ProgressBarBlue"
			$SmartPanel/HBoxContainer/VList/HBoxContainer/recomendation_hint.hash_tag_color = "BLUE"
		"too_hard":
			$SmartPanel/HBoxContainer/IconBG.panel_color = "RED"
			$SmartPanel/HBoxContainer/VList/ProgressBar.theme_type_variation = "ProgressBarRed"
			$SmartPanel/HBoxContainer/VList/HBoxContainer/recomendation_hint.hash_tag_color = "RED"

func SetMaxProgress(max_progress:int):
	await get_tree().process_frame
	
	$SmartPanel/HBoxContainer/VList/ProgressBar.max_value = int(max_progress)
	$SmartPanel/HBoxContainer/VList/ProgressBar.value = int(cur_data.coins_per_hour + cur_data.crystals_per_hour + cur_data.energy_per_hour)


func _on_setting_toggle_is_toggled(toggled_on: bool) -> void:
	if toggled_on:
		GlobalOfflineProgress.SetSelectedOfflineBand(cur_data.band_index)
		GlobalSignals.SelectedOfflineBandSync.emit(cur_data.band_index)
