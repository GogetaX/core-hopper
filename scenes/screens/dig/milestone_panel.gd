extends Control

@onready var currency_reward_item = preload("res://scenes/screens/dig/milestone_reward_item.tscn")

var cur_milestone_data = {}
func _ready() -> void:
	GlobalSignals.DataSaved.connect(OnDataUpdated)
	OnDataUpdated()
	
	
func OnDataUpdated():
	HideAllMilestones()
	CleanRewardContainer()
	cur_milestone_data = GlobalMilestone.get_next_milestone()
	#print(cur_milestone_data)
	if cur_milestone_data.is_empty():
		$Milestone_NoMilestoneLeft.visible = true
	elif cur_milestone_data.is_completed:
		$Milestone_Completed.visible = true
		$Milestone_Completed/VList/title.text = cur_milestone_data.title
		match cur_milestone_data.reward_type:
			"coins","energy","crystals":
				var c : MilestoneCurrencyClass = currency_reward_item.instantiate()
				$Milestone_Completed/VList/RewardContainer.add_child(c)
				c.InitItem(cur_milestone_data.reward_type,cur_milestone_data.reward_value)
			_:
				print_debug("Unknown reward type: ",cur_milestone_data.reward_type)
	else:
		$Milestone_Incomplete.visible = true
		$Milestone_Incomplete/VList/title.text = cur_milestone_data.title
		$Milestone_Incomplete/VList/description.text = cur_milestone_data.description

func CleanRewardContainer():
	for x in $Milestone_Completed/VList/RewardContainer.get_children():
		x.queue_free()
func HideAllMilestones():
	for x in get_children():
		x.visible = false


func _on_claim_btn_on_pressed() -> void:
	match cur_milestone_data.reward_type:
		"coins","energy","crystals":
			GlobalSave.AddCurrency(cur_milestone_data.reward_type,cur_milestone_data.reward_value)
			GlobalSignals.ShowCurrencyAnimation.emit(global_position+(size/2),cur_milestone_data.reward_type,10)
			GlobalSave.SetMilestoneToClaimed(cur_milestone_data.id)
			GlobalSave.SyncSave()
		_:
			print_debug("Unkwnon reward type: ",cur_milestone_data.reward_type)
