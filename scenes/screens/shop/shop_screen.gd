extends VBoxContainer
@onready var daily_deal = preload("res://scenes/screens/shop/daily_deal_item.tscn")

func _ready() -> void:
	InitDailyDeals()
	InitTacticalBoosters()
	InitCrystalPacksWithMoney()

func InitCrystalPacksWithMoney():
	$BuyWithMoney.visible = false
	$SpecialOffser.visible = false
	$BuyWithCurrency.visible = true
	
func InitDailyDeals():
	#Remove old
	for x in $DailyDealList.get_children():
		x.queue_free()
	var daily_deal_items = GlobalTimedBonus.GetDailyRandom(2)
	for x in daily_deal_items:
		var d = daily_deal.instantiate() as DailyDealClass
		$DailyDealList.add_child(d)
		d.InitDaily(x,true)
	
func InitTacticalBoosters():
	#Remov old 
	for x in $TacticalBoosters.get_children():
		x.queue_free()
		
	var tactical_booster_ids = ["auto_merge","bot_discount","double_dps","double_coins"]
	for x in 4:
		var booster = tactical_booster_ids[0]
		var booster_data = GlobalTimedBonus.GetBoosterDataById(booster)
		tactical_booster_ids.erase(booster)
		var d = daily_deal.instantiate() as DailyDealClass
		$TacticalBoosters.add_child(d)
		d.InitTactical(booster_data)
