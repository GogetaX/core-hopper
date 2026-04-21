extends Control

@onready var offline_band_item = preload("res://scenes/components/offline_band_selector.tscn")

var cur_selected_band_index = -1
var new_selected_band_index = -1

func _ready() -> void:
	GlobalSignals.SelectedOfflineBandSync.connect(SyncBand)
	InitBands()
	
func SyncBand(selected_band_index:int):
	new_selected_band_index = selected_band_index
	InitBands(true)
	
func InitBands(sync_selected:=false):
	var offline_bands = GlobalOfflineProgress.GetAvailableBands()
	
	#Init Top Stats
	
	var selected_band_data = GetBandIndex(offline_bands,offline_bands.selected_band_index)
	$SmartPanel/VBoxContainer/SelectedTarget/VList/HList/selected_slot.text = selected_band_data.title.to_upper()
	$SmartPanel/VBoxContainer/HBoxContainer/ActiveBots2/VList/offline_dps.text = Global.CurrencyToString(offline_bands.total_offline_dps)
	
	$SmartPanel/VBoxContainer/SelectedTarget/VList/HList2/selected_band_depth.text = str(selected_band_data.min_depth).pad_decimals(0)+"-"+str(selected_band_data.max_depth).pad_decimals(0)+"m"
	$SmartPanel/VBoxContainer/SelectedTarget/VList/HList2/representive_depth.text = str(selected_band_data.representative_depth).pad_decimals(0)+"m"
	$SmartPanel/VBoxContainer/SelectedTarget/VList/ClearRate/HList/clear_rate_ph.text = str(snapped(selected_band_data.blocks_per_hour,0.1))+"/h"
	$SmartPanel/VBoxContainer/SelectedTarget/VList/HList3/CoinCurrencyGain/VList/coins_ph.text = Global.CurrencyToString(selected_band_data.coins_per_hour)
	$SmartPanel/VBoxContainer/SelectedTarget/VList/HList3/CrystalCurrencyGan/VList/crystals_ph.text = Global.CurrencyToString(selected_band_data.crystals_per_hour)
	$SmartPanel/VBoxContainer/SelectedTarget/VList/HList3/EnergyCurrencyGan/VList/energy_ph.text = Global.CurrencyToString(selected_band_data.energy_per_hour)
	#Offline Target: 600-799m
	$SmartPanel/VBoxContainer/SmartPanel/VList/selected_target.text = "Offline Target: "+str(selected_band_data.min_depth).pad_decimals(0)+"-"+str(selected_band_data.max_depth).pad_decimals(0)+"m"
	$SmartPanel/VBoxContainer/SmartPanel/VList/HList2/expected_coins.text = Global.CurrencyToString(selected_band_data.coins_per_hour)
	$SmartPanel/VBoxContainer/SmartPanel/VList/HList2/expected_crystals.text = Global.CurrencyToString(selected_band_data.crystals_per_hour)
	$SmartPanel/VBoxContainer/SmartPanel/VList/HList2/expected_energy.text = Global.CurrencyToString(selected_band_data.energy_per_hour)
	
	var upgrade_value = GlobalStats.GetOfflineCapSeconds()
	$SmartPanel/VBoxContainer/HBoxContainer/OfflineCap/VList/offline_cap.text = Global.SecondsToPrettyTimeString(upgrade_value)
	#Offline bot count
	var count :int = 0
	for x in GlobalSave.save_data.lanes:
		if !x.is_empty():
			if x.auto_dig_unlocked && x.bot_uid != -1:
				count += 1
	$SmartPanel/VBoxContainer/HBoxContainer/ActiveBots/VList/active_bots.text = str(count).pad_decimals(0)
	
	if !sync_selected:
		#Remove old offline bands
		for x in $SmartPanel/VBoxContainer/AvailableDepthList.get_children():
			x.queue_free()
		
		#Create new offline bands
		var max_progress_bar = 0
		var bands_list = []
		for x in offline_bands.bands:
			if bands_list.has(x.band_index):
				continue
			bands_list.append(x.band_index)
			var b = offline_band_item.instantiate() as OfflineBandSelectorClass
			if x.is_selected:
				cur_selected_band_index = x.band_index
				new_selected_band_index = x.band_index
			b.InitBandData(x)
			if x.coins_per_hour + x.crystals_per_hour+x.energy_per_hour > max_progress_bar:
				max_progress_bar = x.coins_per_hour + x.crystals_per_hour+x.energy_per_hour
			$SmartPanel/VBoxContainer/AvailableDepthList.add_child(b)
		#Set Set Max Progress for each band
		for x in $SmartPanel/VBoxContainer/AvailableDepthList.get_children():
			if x is OfflineBandSelectorClass:
				x.SetMaxProgress(int(max_progress_bar))
func GetBandIndex(offline_data:Dictionary,band_index:int)->Dictionary:
	for x in offline_data.bands:
		if x.band_index == band_index:
			return x
	return {}
func _on_v_box_container_resized() -> void:
	var max_y = $SmartPanel/VBoxContainer.get_minimum_size().y
	custom_minimum_size.y = max_y + 35
	await get_tree().process_frame
	size.y = custom_minimum_size.y


func _on_close_btn_on_pressed() -> void:
	GlobalOfflineProgress.SetSelectedOfflineBand(cur_selected_band_index)
	GlobalSignals.CloseCurPopup.emit()


func _on_select_btn_on_pressed() -> void:
	GlobalOfflineProgress.SetSelectedOfflineBand(new_selected_band_index)
	GlobalSignals.CloseCurPopup.emit()
