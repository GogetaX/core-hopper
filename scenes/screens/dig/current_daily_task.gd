extends Control

@onready var currency_reward_item = preload("res://scenes/screens/dig/milestone_reward_item.tscn")

var cur_active_quest = {}

func _ready() -> void:
	GlobalSignals.DataSaved.connect(SyncData)
	GlobalSignals.AllQuestsInited.connect(SyncData)
	SyncData()
	
	
func HideAllMenus():
	for x in get_children():
		x.visible = false
	
func CleanRewardContainer():
	for x in $Quest_Completed/VList/RewardContainer.get_children():
		x.queue_free()
		
func SyncData():
	HideAllMenus()
	CleanRewardContainer()
	var active_quest = GlobalDailyQuest.GetMostProgressedActiveQuest(true,false)
	cur_active_quest = active_quest
	if active_quest.is_empty():
		$NoQuestsLeft.visible = true
	elif active_quest.is_complete:
		$Quest_Completed.visible = true
		$Quest_Completed/VList/title.text = active_quest.desc
		for x in active_quest.reward:
			if active_quest.reward[x] > 0:
				var c : MilestoneCurrencyClass = currency_reward_item.instantiate()
				$Quest_Completed/VList/RewardContainer.add_child(c)
				c.InitItem(x,active_quest.reward[x])
	else:
		$CurActiveQuest.visible = true
		$CurActiveQuest/VList/cur_task_name.text = active_quest.desc
		$CurActiveQuest/VList/ProgressBar.max_value = active_quest.target
		$CurActiveQuest/VList/ProgressBar.value = active_quest.progress
		var percent_completed = (active_quest.progress * 100) / active_quest.target
		$CurActiveQuest/VList/percent_complete.text = str(snapped(percent_completed,1))+"% complete"


func _on_claim_btn_on_pressed() -> void:
	if cur_active_quest.is_empty():
		return
	if cur_active_quest.reward.is_empty():
		return
	for x in cur_active_quest.reward:
		GlobalSignals.ShowCurrencyAnimation.emit(global_position+(size/2),x,10)
		GlobalDailyQuest.ClaimQuest(cur_active_quest.id)
	
	GlobalSave.SyncSave()
		#_:
			#print_debug("Unkwnon reward type: ",cur_milestone_data.reward_type)
