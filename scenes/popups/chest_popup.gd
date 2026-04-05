extends Control

@onready var chest_item = preload("res://scenes/components/chest_reward.tscn")
@onready var chest_list = $SmartPanel/VBoxContainer/Scroll/HList

func _ready() -> void:
	ShowChests()

func ShowChests():
	#Remove all other chests
	for x in chest_list.get_children():
		x.queue_free()
	#Add Chests based on GlobalRewardChests
	var reward_queue = GlobalRewardChest.GetRewardChestQueue()
	for x in reward_queue:
		var c = chest_item.instantiate() as ChestItemClass
		c.InitItem(x)
		chest_list.add_child(c)
		c.OnPress.connect(OnOpenChestPress)
		
	#Pending amount
	$SmartPanel/VBoxContainer/pendin_amount.text = str(GlobalRewardChest.GetRewardChestCount()).pad_decimals(0)+" PENDING REWARDS"
func _on_close_popup_btn_pressed() -> void:
	GlobalSignals.CloseCurPopup.emit()

func OnOpenChestPress(item_data:Dictionary):
	GlobalSignals.ShowPopup.emit("SHOW_CHEST_DROP",item_data)
