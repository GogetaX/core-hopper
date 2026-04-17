extends Node

const AD_ID_DEPTH_CACHE := "depth_cache"
const AD_ID_RELIC_CRATE := "relic_crate"
const AD_ID_BOT_DROP := "bot_drop"

const WATCH_AD_DATA := {
	"id": "",
	"icon": null,
	"title": "",
	"description": "",
	"max_times": 2,
	"times_left": 2,
	"color": "BLUE",
	"rewards": []
}

func _ready() -> void:
	InitTodayKey()


func GetWatchAdData() -> Array:
	InitTodayKey()

	var res: Array = []
	res.append(_GainCurrencyAd())
	res.append(_RelicCrateAd())
	res.append(_BotDropAd())
	return res


func InitTodayKey() -> void:
	if !GlobalSave.save_data.has("daily_watch_ads") or typeof(GlobalSave.save_data.daily_watch_ads) != TYPE_DICTIONARY:
		GlobalSave.save_data["daily_watch_ads"] = {"day_key": ""}

	var today_key := _GetTodayKey()
	if str(GlobalSave.save_data.daily_watch_ads.get("day_key", "")) != today_key:
		GlobalSave.save_data.daily_watch_ads.clear()
		GlobalSave.save_data.daily_watch_ads["day_key"] = today_key


func GetMaxDailyUsesForAds(ad_id: String) -> int:
	match ad_id:
		AD_ID_DEPTH_CACHE:
			return 5
		AD_ID_RELIC_CRATE:
			return 1
		AD_ID_BOT_DROP:
			return 2
		_:
			return 0


func GetTimesLeft(ad_id: String) -> int:
	InitTodayKey()

	if GlobalSave.save_data.daily_watch_ads.has(ad_id):
		return maxi(0, int(GlobalSave.save_data.daily_watch_ads[ad_id]))

	return GetMaxDailyUsesForAds(ad_id)


func ConsumeAdUse(ad_id: String) -> bool:
	var times_left := GetTimesLeft(ad_id)
	if times_left <= 0:
		return false

	GlobalSave.save_data.daily_watch_ads[ad_id] = times_left - 1
	return true


func CanWatchAd(ad_id: String) -> bool:
	return GetTimesLeft(ad_id) > 0


func _GainCurrencyAd() -> Dictionary:
	var res: Dictionary = WATCH_AD_DATA.duplicate(true)

	var depth = max(1, int(GlobalSave.save_data.progress.get("global_depth", 1)))
	var coins := int(max(250, depth * 100))
	var crystals := int(max(1, depth / 100))

	res.id = AD_ID_DEPTH_CACHE
	res.icon = "res://art/skills/resource_drop_mult.tres"
	res.color = "BLUE"
	res.title = "Depth Cache"
	res.description = "Gain %d Coins and %d Crystals instantly" % [coins, crystals]
	res.max_times = GetMaxDailyUsesForAds(res.id)
	res.times_left = GetTimesLeft(res.id)
	res.rewards.append({"coins": coins})
	res.rewards.append({"crystals": crystals})

	return res


func _RelicCrateAd() -> Dictionary:
	var res: Dictionary = WATCH_AD_DATA.duplicate(true)

	res.id = AD_ID_RELIC_CRATE
	res.icon = "res://art/skills/relic_find.tres"
	res.color = "GOLD"
	res.title = "Relic Crate"
	res.description = "Open 1 random Relic Crate"
	res.max_times = GetMaxDailyUsesForAds(res.id)
	res.times_left = GetTimesLeft(res.id)

	# Preview only. Roll the actual relic after the ad succeeds.
	res.rewards.append({"random_relic_crate": 1})

	return res


func _BotDropAd() -> Dictionary:
	var res: Dictionary = WATCH_AD_DATA.duplicate(true)

	var bot_level := _GetAdBotRewardLevel()

	res.id = AD_ID_BOT_DROP
	res.icon = "res://art/skills/bot_buy_start_level_bonus.tres"
	res.color = "PURPLE"
	res.title = "Bot Drop"
	res.description = "Get 1 random Level %d Bot instantly" % bot_level
	res.max_times = GetMaxDailyUsesForAds(res.id)
	res.times_left = GetTimesLeft(res.id)

	# Preview only. Roll/create the actual bot after the ad succeeds.
	res.rewards.append({
		"random_bot_level": bot_level,
		"amount": 1
	})

	return res


func _GetAdBotRewardLevel() -> int:

	var buy_bot_data = GlobalStats.BuyBotData()
	return int(buy_bot_data.level + 1)

func _GetTodayKey() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [
		int(d.get("year", 1970)),
		int(d.get("month", 1)),
		int(d.get("day", 1))
	]
