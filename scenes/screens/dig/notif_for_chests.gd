extends Node

func _ready() -> void:
	GlobalSignals.DataSaved.connect(SyncData)
	get_parent().ready.connect(OnParentReady)
	
func OnParentReady():
	SyncData()
	
func SyncData():
	var reward_count = GlobalRewardChest.GetChestCount()
	get_parent().SetNotifCounter(reward_count)
