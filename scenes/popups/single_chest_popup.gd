extends Control

@onready var reward_currency = preload("res://scenes/components/reward_currency.tscn")
@onready var reward_item = preload("res://scenes/components/reward_item.tscn")

var cur_chest_data = {}

func InitChest(data:Dictionary):
	cur_chest_data = data
	#Remove old currency rewards
	for x in $SmartPanel/VBoxContainer/CurrencyList.get_children():
		x.queue_free()
	
	#Populate currency rewards
	for x in cur_chest_data.data.rewards:
		if ["coins","crystals","energy"].has(x) && cur_chest_data.data.rewards[x] > 0:
			var r = reward_currency.instantiate() as RewardCurrencyClass
			$SmartPanel/VBoxContainer/CurrencyList.add_child(r)
			r.currency_type = x.to_upper()
			r.amount_str = Global.CurrencyToString(cur_chest_data.data.rewards[x])

	#Remove Reward Items
	for x in $SmartPanel/VBoxContainer/Scroll/RewardContainer.get_children():
		x.queue_free()
	
	#Populate Relic container
	for x in cur_chest_data.data.rewards.relic_ids:
		var r = reward_item.instantiate() as RewardItemClass
		$SmartPanel/VBoxContainer/Scroll/RewardContainer.add_child(r)
		r.InitRelic(x)
		
	if cur_chest_data.data.source_type == "boss":
		$SmartPanel/VBoxContainer/harvest_from.text = "BOSS DEFEATED"
	else:
		print_debug("Unknown enemy source: ",cur_chest_data.data.source_type)
		$SmartPanel/VBoxContainer/harvest_from.text = cur_chest_data.data.source_type
	$SmartPanel/VBoxContainer/enemy_name.text = cur_chest_data.data.source_name


func _on_return_back_btn_pressed() -> void:
	GlobalMusic.SFX_UIBack()
	GlobalSignals.ShowPopup.emit("SHOW_CHESTS",{})


func _on_open_all_btn_on_pressed() -> void:
	for x in $SmartPanel/VBoxContainer/CurrencyList.get_children():
		if x is RewardCurrencyClass:
			var coin_pos = x.GetCurrencyCenterGlobalPos()
			GlobalSignals.ShowCurrencyAnimation.emit(coin_pos,x.currency_type.to_lower(),8)
	GlobalRewardChest.OpenChest(cur_chest_data.chest_id)
	GlobalSignals.ShowPopup.emit("SHOW_CHESTS",{})
