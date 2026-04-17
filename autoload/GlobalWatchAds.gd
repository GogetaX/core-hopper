extends Node

const WATCH_AD_DATA = {"icon":null,"title":"","description":"","max_times":2,"times_left":2,"color":"BLUE","rewards":[]}

func _ready() -> void:
	InitTodayKey()
	
func GetWatchAdData():
	var res = []
	var gain_currency = _GainCurrencyAd()
	if !gain_currency.is_empty():
		res.append(gain_currency)
	return res
	
func InitTodayKey():
	if GlobalSave.save_data.daily_watch_ads.day_key != _GetTodayKey():
		GlobalSave.save_data.daily_watch_ads.day_key = _GetTodayKey()
		
func GetMaxDailyUsesForAds(ad_title:String)->int:
	match ad_title:
		"Depth Cache":
			return 5
		_:
			return 2
func GetTimesLeft(ad_title):
	if GlobalSave.save_data.daily_watch_ads.has(ad_title):
		return GlobalSave.save_data.daily_watch_ads[ad_title]
	else:
		return GetMaxDailyUsesForAds(ad_title)
		
func _GainCurrencyAd():
	var res = {}
	#New day
	var depth = max(1, int(GlobalSave.save_data.progress.get("global_depth", 1)))
	
	var coins = int(max(250, depth * 100))
	var crystals = int(max(1, depth / 100))
	
	res = WATCH_AD_DATA.duplicate()
	res.icon = preload("res://art/icons/20_px/coin_icon.png")
	res.color = "BLUE"
	res.title = "Depth Cache"
	res.description = "Gain "+str(coins).pad_decimals(0)+" Coins and "+str(crystals).pad_decimals(0)+" Crystals instantly"
	res.max_times = GetMaxDailyUsesForAds(res.title)
	res.times_left = GetTimesLeft(res.title)
	res.rewards.append({"coins":coins})
	res.rewards.append({"crystals":coins})
	return res


func _GetTodayKey() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [
		int(d.get("year", 1970)),
		int(d.get("month", 1)),
		int(d.get("day", 1))
	]
