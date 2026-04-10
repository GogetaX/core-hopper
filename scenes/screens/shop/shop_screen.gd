extends VBoxContainer
@onready var daily_deal = preload("res://scenes/screens/shop/daily_deal_item.tscn")

func _ready() -> void:
	InitDailyDeals()
	
func InitDailyDeals():
	#Remove old
	for x in $DailyDealList.get_children():
		x.queue_free()
	var daily_deal_items = GlobalTimedBonus.GetDailyRandom(2)
	for x in daily_deal_items:
		var d = daily_deal.instantiate() as DailyDealClass
		$DailyDealList.add_child(d)
		d.InitDaily(x,true)
