extends Control

@onready var reward_currency = preload("res://scenes/components/reward_currency.tscn")
@onready var extracted_ordes = preload("res://scenes/components/reward_extracted_rare_ores.tscn")
var cur_rewards = {}
func _ready() -> void:
	SyncYSize()
	_on_offline_time_list_resized()
	
func InitOfflineReward(reward_data:Dictionary):
	cur_rewards = reward_data.duplicate()
	#set offline time
	$SmartPanel/VBoxContainer/HList3/OfflinePanel/OfflineTimeList/offline_time_label.text = Global.SecondsToPrettyTimeString(reward_data.offline_seconds)
	$SmartPanel/VBoxContainer/HList3/OfflineCapTime/OfflineTimeList/offline_time_label.text = Global.SecondsToPrettyTimeString(GlobalStats.GetOfflineCapSeconds())
	#clean currency list #
	for x in $SmartPanel/VBoxContainer/CurrencyList.get_children():
		x.queue_free()
	if reward_data.coins > 0:
		var coin = reward_currency.instantiate()
		coin.currency_type = "COINS"
		coin.amount_str = Global.CurrencyToString(reward_data.coins)
		$SmartPanel/VBoxContainer/CurrencyList.add_child(coin)
	if reward_data.crystals > 0:
		var crystal = reward_currency.instantiate()
		crystal.currency_type = "CRYSTALS"
		crystal.amount_str = Global.CurrencyToString(reward_data.crystals)
		$SmartPanel/VBoxContainer/CurrencyList.add_child(crystal)
	if reward_data.energy > 0:
		var energy = reward_currency.instantiate()
		energy.currency_type = "ENERGY"
		energy.amount_str = Global.CurrencyToString(reward_data.energy)
		$SmartPanel/VBoxContainer/CurrencyList.add_child(energy)
	if !reward_data.drop_data.is_empty():
		var extracted = extracted_ordes.instantiate()
		$SmartPanel/VBoxContainer/RareOresContainer.add_child(extracted)
		extracted.InitData(reward_data.drop_data)
	
	
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


func _on_offline_time_list_resized() -> void:
	await get_tree().process_frame
	var max_x = $SmartPanel/VBoxContainer/HList3/OfflinePanel/OfflineTimeList.get_minimum_size().x
	$SmartPanel/VBoxContainer/HList3/OfflinePanel.custom_minimum_size.x = max_x + 30
	
	var max_x_cap = $SmartPanel/VBoxContainer/HList3/OfflineCapTime/OfflineTimeList.get_minimum_size().x
	$SmartPanel/VBoxContainer/HList3/OfflineCapTime.custom_minimum_size.x = max_x_cap + 30


func _on_simple_btn_on_pressed() -> void:
	GainRewardAndClose(1.0)

func GainRewardAndClose(gain_multiplayer:float):
	#disable input
	GlobalSignals.StopScreenClick.emit(true)
	#Add currency to data
	GlobalSave.AddCurrency("coins",cur_rewards.coins*gain_multiplayer)
	GlobalSave.AddCurrency("crystals",cur_rewards.crystals*gain_multiplayer)
	GlobalSave.AddCurrency("energy",cur_rewards.energy*gain_multiplayer)
	#add drop data
	#<Empty for now>
	#animate currencies
	for x in $SmartPanel/VBoxContainer/CurrencyList.get_children():
		if x is RewardCurrencyClass:
			var coin_pos = x.GetCurrencyCenterGlobalPos()
			GlobalSignals.ShowCurrencyAnimation.emit(coin_pos,x.currency_type.to_lower(),8*gain_multiplayer)
	
	#Save State
	GlobalSave.SyncSave()
	#animate popup out
	GlobalSignals.CloseCurPopup.emit()


func _on_watch_ad_btn_on_ad_gained() -> void:
	GainRewardAndClose(2.0)
