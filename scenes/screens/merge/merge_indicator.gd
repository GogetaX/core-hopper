extends Control

@export var booster_id := "auto_merge"

func _ready() -> void:
	GlobalSignals.DataSaved.connect(SyncData)
	SyncData()
	
func SyncData():
	HideAll()
	var active_boosters = GlobalTimedBonus.GetActivatedBoosterIds()
	$MergeActive/skill_tick.stop()
	if active_boosters.has(booster_id):
		$MergeActive/skill_tick.start()
		$MergeActive.visible = true
		var bonus_data = GlobalTimedBonus.GetActivatedBoosterData(booster_id)
		$MergeActive/HList/VList/title.text = bonus_data.title.to_upper()
		_on_skill_tick_timeout()
	else:
		$MergeNotActive.visible = true


func _on_skill_tick_timeout() -> void:
	var active_boosters = GlobalTimedBonus.GetActivatedBoosterIds()
	if active_boosters.has(booster_id):
		var bonus_data = GlobalTimedBonus.GetActivatedBoosterData(booster_id)
		$MergeActive/HList/VList/time_left.text = Global.SecondsToPrettyTimeString(bonus_data.remaining_sec)+" left"

func HideAll():
	for x in get_children():
		x.visible = false


func _on_activate_merge_btn_on_press() -> void:
	var ad_result = await GlobalCrazyGames.OnWatchRewardedAd()
	if ad_result == GlobalCrazyGames.AD_REWARD_SUCCESS:
		GlobalTimedBonus.ActivateBooster("auto_merge",false)
