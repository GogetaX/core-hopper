extends Control

class_name QuestItemClass

@onready var reward_currency = preload("res://scenes/screens/dig/milestone_reward_item.tscn")

var cur_data = {}

func InitDailyQuestItem(data):
	cur_data = data
	HideAllPanels()
	if data.is_complete:
		$QuestItem_Complete.visible = true
		$QuestItem_Complete/VList/HList/VList/quest_desc.text = data.desc
		for x in $QuestItem_Complete/VList/HList/VList2/RewardContainer.get_children():
			x.queue_free()
		for x in data.reward:
			if data.reward[x]>0:
				var r = reward_currency.instantiate() as MilestoneCurrencyClass
				r.InitItem(x,data.reward[x])
				$QuestItem_Complete/VList/HList/VList2/RewardContainer.add_child(r)
		
	else:
		$QuestItem_Incomplete.visible = true
		$QuestItem_Incomplete/VList/HList/VList/quest_desc.text = data.desc
		$QuestItem_Incomplete/VList/ProgressBar.max_value = data.target
		$QuestItem_Incomplete/VList/ProgressBar.value = data.progress
		$QuestItem_Incomplete/VList/HList/VList/progress_text.text = str(data.progress).pad_decimals(0)+" / "+str(data.target).pad_decimals(0)+" complete"
		#Clearing reward container
		for x in $QuestItem_Incomplete/VList/HList/VList2/RewardContainer.get_children():
			x.queue_free()
		for x in data.reward:
			if data.reward[x]>0:
				var r = reward_currency.instantiate() as MilestoneCurrencyClass
				r.InitItem(x,data.reward[x])
				$QuestItem_Incomplete/VList/HList/VList2/RewardContainer.add_child(r)
		
func InitMilestoneItem(data):
	print("Milestone Item: ")
	print(data)
	cur_data = data
	HideAllPanels()
	if data.has("is_completed") && data.is_completed:
		$MilestoneItem_Complete.visible = true
		$MilestoneItem_Complete/VList/HList/VList/milestone_title.text = data.description
		#Clearing reward container
		for x in $MilestoneItem_Complete/VList/HList/VList2/RewardContainer.get_children():
			x.queue_free()
		var r = reward_currency.instantiate() as MilestoneCurrencyClass
		r.InitItem(cur_data.reward_type,cur_data.reward_value)
		$MilestoneItem_Complete/VList/HList/VList2/RewardContainer.add_child(r)
	else:
		$MilestoneItem_Incomplete.visible = true
		$MilestoneItem_Incomplete/VList/HList/VList/milestone_title.text = data.title
		$MilestoneItem_Incomplete/VList/HList/VList/milestone_subtitle.text = data.description
		#Clearing reward container
		for x in $MilestoneItem_Incomplete/VList/HList/VList2/RewardContainer.get_children():
			x.queue_free()
		var r = reward_currency.instantiate() as MilestoneCurrencyClass
		r.InitItem(cur_data.reward_type,cur_data.reward_value)
		$MilestoneItem_Incomplete/VList/HList/VList2/RewardContainer.add_child(r)

	#$SmartPanel/VList/HList/VList/quest_desc.text = data.description
	#$SmartPanel/VList/ProgressBar.max_value = data.target_value
	#$SmartPanel/VList/ProgressBar.value = data.progress
	#$SmartPanel/VList/HList/VList/progress_text.text = str(data.progress).pad_decimals(0)+" / "+str(data.target).pad_decimals(0)+" complete"

func HideAllPanels():
	for x in get_children():
		x.visible = false


func _on_daily_quest_complete_btn_on_pressed() -> void:
	if cur_data.is_empty():
		return
	if cur_data.reward.is_empty():
		return
	for x in cur_data.reward:
		GlobalSignals.ShowCurrencyAnimation.emit(global_position+(size/2),x,10)
		GlobalDailyQuest.ClaimQuest(cur_data.id)
	
	GlobalSave.SyncSave()
	var t = create_tween()
	t.tween_property(self,"custom_minimum_size:y",0,0.1)
	t.finished.connect(func():queue_free())


func _on_milestone_btn_complete_on_pressed() -> void:
	match cur_data.reward_type:
		"coins","energy","crystals":
			GlobalSave.AddCurrency(cur_data.reward_type,cur_data.reward_value)
			GlobalSignals.ShowCurrencyAnimation.emit(global_position+(size/2),cur_data.reward_type,10)
			GlobalSave.SetMilestoneToClaimed(cur_data.id)
			GlobalSave.SyncSave()
		_:
			print_debug("Unkwnon reward type: ",cur_data.reward_type)
	var t = create_tween()
	t.tween_property(self,"custom_minimum_size:y",0,0.1)
	t.finished.connect(func():queue_free())
