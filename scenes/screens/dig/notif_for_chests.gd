extends Node

func _ready() -> void:
	GlobalSignals.DataSaved.connect(SyncData)
	get_parent().ready.connect(OnParentReady)
	
func OnParentReady():
	SyncData()
	Global.chest_btn_node = get_parent()
	
func SyncData():
	var reward_count = GlobalRewardChest.GetChestCount()
	get_parent().SetNotifCounter(reward_count)


func _on_tree_exiting() -> void:
	Global.chest_btn_node = null
