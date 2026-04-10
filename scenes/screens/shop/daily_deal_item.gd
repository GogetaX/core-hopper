@tool
extends Control
class_name DailyDealClass


var cur_data := {}
var cur_watch_ads := false

func _ready() -> void:
	if !Engine.is_editor_hint():
		GlobalSignals.SyncActivatedBooster.connect(SyncActivatedBooster)

func SyncActivatedBooster(booster_id:String):
	if cur_data.is_empty():
		return
	if cur_data.id == booster_id:
		var boost_data = GlobalTimedBonus.GetActivatedBoosterData(booster_id)
		InitDaily(boost_data,cur_watch_ads)
	

func InitDaily(data:Dictionary,watch_ads := false):
	cur_data = data
	cur_watch_ads = watch_ads
	
	#Set Colors
	$SmartPanel.panel_color = GlobalColor.GetSkillBranchColor(cur_data.group)
	$SmartPanel/VBoxContainer/BuyBtn.panel_color = GlobalColor.GetSkillBranchColor(cur_data.group)
	$SmartPanel/VBoxContainer/HList/Control/IconBG.panel_color = GlobalColor.GetSkillBranchColor(cur_data.group)
	$SmartPanel/VBoxContainer/time_left.hash_tag_color = GlobalColor.GetSkillBranchColor(cur_data.group)
	
	#Set Data
	$SmartPanel/VBoxContainer/HList/VList/item_title.text = cur_data.title
	$SmartPanel/VBoxContainer/HList/VList/sub_title.text = cur_data.description
	$SmartPanel/VBoxContainer/duration.text = Global.SecondsToPrettyTimeString(cur_data.duration_sec)
	$SmartPanel/VBoxContainer/HList/Control/IconBG.icon = GlobalTimedBonus.GetIcon(cur_data.icon)
	
	#Hide all the dynamic buttons
	$SmartPanel/VBoxContainer/BuyBtn.visible = false
	$SmartPanel/VBoxContainer/time_left.visible = false
	$count_down.stop()
	#BuyBtn if !is_active
	if !cur_data.is_active:
		$SmartPanel/VBoxContainer/BuyBtn.visible = true
	elif cur_data.remaining_sec > 0:
		$SmartPanel/VBoxContainer/time_left.visible = true
		$count_down.start()
		_on_count_down_timeout()
	else:
		$SmartPanel/VBoxContainer/time_left.visible = true
		$SmartPanel/VBoxContainer/time_left.text = "CHECK BACK TOMORROW"
	
	if watch_ads:
		$SmartPanel/VBoxContainer/BuyBtn.buy_btn_title = "FREE"
		$SmartPanel/VBoxContainer/BuyBtn.buy_btn_icon = load("res://art/icons/20_px/play_icon.png")
	


func _on_buy_btn_on_press() -> void:
	GlobalTimedBonus.ActivateBooster(cur_data.id,false)


func _on_count_down_timeout() -> void:
	if !cur_data.is_empty():
		var d = GlobalTimedBonus.GetActivatedBoosterData(cur_data.id)
		$SmartPanel/VBoxContainer/time_left.text = "ACTIVE: "+Global.SecondsToPrettyTimeString(d.remaining_sec)
	
