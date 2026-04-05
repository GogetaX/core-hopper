extends Control

@onready var reward_currency = preload("res://scenes/components/reward_currency.tscn")
@onready var reward_item = preload("res://scenes/components/reward_item.tscn")

func InitChest(data:Dictionary):
	print(data)
	#Remove old currency rewards
	for x in $SmartPanel/VBoxContainer/CurrencyList.get_children():
		x.queue_free()
	
	#Populate currency rewards
	for x in data.rewards:
		if ["coins","crystals","energy"].has(x) && data.rewards[x] > 0:
			var r = reward_currency.instantiate() as RewardCurrencyClass
			$SmartPanel/VBoxContainer/CurrencyList.add_child(r)
			r.currency_type = x
			r.amount_str = Global.CurrencyToString(data.rewards[x])
	
	#Remove Reward Items
	for x in $SmartPanel/VBoxContainer/Scroll/RewardContainer.get_children():
		x.queue_free()
	
	#Populate reward container
	for x in data.rewards.relic_ids:
		var r = reward_item.instantiate() as RewardItemClass
		$SmartPanel/VBoxContainer/Scroll/RewardContainer.add_child(r)
		r.InitItem(x)
		
	if data.source_type == "boss":
		$SmartPanel/VBoxContainer/harvest_from.text = "BOSS DEFEATED"
	else:
		print_debug("Unknown enemy source: ",data.source_type)
		$SmartPanel/VBoxContainer/harvest_from.text = data.source_type
	$SmartPanel/VBoxContainer/enemy_name.text = data.source_name


func _on_return_back_btn_pressed() -> void:
	#GlobalSignals.CloseCurPopup.emit()
	GlobalSignals.ShowPopup.emit("SHOW_CHESTS",{})
