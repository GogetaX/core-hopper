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
	var chest_id = 0
	for x in reward_queue:
		var c = chest_item.instantiate() as ChestItemClass
		c.InitItem(x,chest_id)
		chest_list.add_child(c)
		c.OnPress.connect(OnOpenChestPress)
		chest_id += 1
		
	#Pending amount
	$SmartPanel/VBoxContainer/pendin_amount.text = str(GlobalRewardChest.GetRewardChestCount()).pad_decimals(0)+" PENDING REWARDS"
func _on_close_popup_btn_pressed() -> void:
	GlobalSignals.CloseCurPopup.emit()

func OnOpenChestPress(item_data:Dictionary,chest_id):
	var d = {"chest_id":chest_id,"data":item_data}
	GlobalSignals.ShowPopup.emit("SHOW_CHEST_DROP",d)


func _on_open_all_btn_on_pressed() -> void:
	GlobalRewardChest.OpenAllChests()
	GlobalSignals.CloseCurPopup.emit()
