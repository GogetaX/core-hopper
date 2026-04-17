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
	HideAll()
	$DailyItem.visible = true
	cur_data = data
	cur_watch_ads = watch_ads
	#Set Colors
	$DailyItem.panel_color = GlobalSkillTree.GetBranchColorStr(cur_data.group)
	$DailyItem/VBoxContainer/BuyBtn.panel_color = GlobalSkillTree.GetBranchColorStr(cur_data.group)
	$DailyItem/VBoxContainer/HList/Control/IconBG.panel_color = GlobalSkillTree.GetBranchColorStr(cur_data.group)
	$DailyItem/VBoxContainer/time_left.hash_tag_color = GlobalSkillTree.GetBranchColorStr(cur_data.group)
	
	#Set Data
	$DailyItem/VBoxContainer/HList/VList/item_title.text = cur_data.title
	$DailyItem/VBoxContainer/HList/VList/sub_title.text = cur_data.description
	$DailyItem/VBoxContainer/duration.text = Global.SecondsToPrettyTimeString(cur_data.duration_sec)
	$DailyItem/VBoxContainer/HList/Control/IconBG.icon = GlobalTimedBonus.GetIcon(cur_data.icon)
	
	#Hide all the dynamic buttons
	$DailyItem/VBoxContainer/BuyBtn.visible = false
	$DailyItem/VBoxContainer/time_left.visible = false
	$count_down.stop()
	#BuyBtn if !is_active
	if !cur_data.is_active:
		$DailyItem/VBoxContainer/BuyBtn.visible = true
	elif cur_data.remaining_sec > 0:
		$DailyItem/VBoxContainer/time_left.visible = true
		$count_down.start()
		_on_count_down_timeout()
	else:
		$DailyItem/VBoxContainer/time_left.visible = true
		$DailyItem/VBoxContainer/time_left.text = "CHECK BACK TOMORROW"
	
	if watch_ads:
		$DailyItem/VBoxContainer/BuyBtn.buy_btn_title = "FREE"
		$DailyItem/VBoxContainer/BuyBtn.buy_btn_icon = load("res://art/icons/20_px/play_icon.png")
	

func InitTactical(data):
	cur_data = data
	cur_watch_ads = false
	HideAll()
	$BuyItem.visible = true
	#Set Colors
	$BuyItem.panel_color = GlobalSkillTree.GetBranchColorStr(cur_data.group)
	$BuyItem/VBoxContainer/HList/Control/IconBG.panel_color = GlobalSkillTree.GetBranchColorStr(cur_data.group)
	$BuyItem/VBoxContainer/time_left.hash_tag_color = GlobalSkillTree.GetBranchColorStr(cur_data.group)
	$BuyItem/VBoxContainer/BuyWithCurrencyBtn.currency_type = cur_data.cost_currency
	$BuyItem/VBoxContainer/BuyWithCurrencyBtn.panel_color = GlobalSkillTree.GetBranchColorStr(cur_data.group)
	
	#Set Data
	$BuyItem/VBoxContainer/HList/VList/item_title.text = cur_data.title
	$BuyItem/VBoxContainer/HList/VList/sub_title.text = cur_data.description
	$BuyItem/VBoxContainer/duration.text = Global.SecondsToPrettyTimeString(cur_data.duration_sec)
	$BuyItem/VBoxContainer/HList/Control/IconBG.icon = GlobalTimedBonus.GetIcon(cur_data.icon)
	$BuyItem/VBoxContainer/BuyWithCurrencyBtn.price_text = Global.CurrencyToString(cur_data.cost_amount)
	$BuyItem/VBoxContainer/BuyWithCurrencyBtn.price_int = Global.CurrencyToString(cur_data.cost_amount)
	
	#Hide all the dynamic buttons
	$BuyItem/VBoxContainer/BuyWithCurrencyBtn.visible = false
	$BuyItem/VBoxContainer/time_left.visible = false
	$count_down.stop()
	if !cur_data.is_active:
		$BuyItem/VBoxContainer/BuyWithCurrencyBtn.visible = true
	elif cur_data.remaining_sec > 0:
		$BuyItem/VBoxContainer/time_left.visible = true
		$count_down.start()
		_on_count_down_timeout()
	else:
		$BuyItem/VBoxContainer/time_left.visible = true
		$BuyItem/VBoxContainer/time_left.text = "CHECK BACK TOMORROW"

func _on_buy_btn_on_press() -> void:
	GlobalTimedBonus.ActivateBooster(cur_data.id,false)

func HideAll():
	for x in get_children():
		if x is Control:
			x.visible = false
			
func _on_count_down_timeout() -> void:
	if !cur_data.is_empty():
		var d = GlobalTimedBonus.GetActivatedBoosterData(cur_data.id)
		$DailyItem/VBoxContainer/time_left.text = "ACTIVE: "+Global.SecondsToPrettyTimeString(d.remaining_sec)
		$BuyItem/VBoxContainer/time_left.text = "ACTIVE: "+Global.SecondsToPrettyTimeString(d.remaining_sec)


func _on_buy_with_currency_btn_btn_pressed_with_price(_currency: String, _price: int) -> void:
	if GlobalTimedBonus.IsDailyBooster(cur_data.id):
		GlobalTimedBonus.ActivateBooster(cur_data.id)
	else:
		GlobalTimedBonus.ActivateNonDailyBooster(cur_data.id)
