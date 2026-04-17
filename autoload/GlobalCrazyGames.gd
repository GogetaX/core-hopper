# GlobalCrazyGames.gd
extends Node

const AD_REWARD_SUCCESS = "SUCCESS"
const AD_REWARD_FAILED = "FAILED"

signal sdk_ready

var is_ready := false

func _ready() -> void:
	await CrazyGames.is_initialised_async()
	is_ready = true
	sdk_ready.emit()

func wait_until_ready() -> void:
	if is_ready:
		return
	await sdk_ready

func gameplay_start() -> void:
	if !is_ready:
		return
	CrazyGames.Game.gameplay_start()

func gameplay_stop() -> void:
	if !is_ready:
		return
	CrazyGames.Game.gameplay_stop()

func happy_time() -> void:
	if !is_ready:
		return
	CrazyGames.Game.happy_time()

func show_rewarded_ad() -> Dictionary:
	if !is_ready:
		return {"state": "sdk_not_ready"}
	var result = await CrazyGames.Ad.request_ad_async("rewarded")
	return result

func show_midgame_ad() -> Dictionary:
	if !is_ready:
		return {"state": "sdk_not_ready"}
	var result = await CrazyGames.Ad.request_ad_async("midgame")
	return result

func save_string(key: String, value: String) -> void:
	if !is_ready:
		return
	CrazyGames.Data.data_set_item(key, value)

func load_string(key: String, fallback: String = "") -> String:
	if !is_ready:
		return fallback
	if CrazyGames.Data.data_has_key(key):
		return str(CrazyGames.Data.data_get_item(key))
	return fallback

func OnWatchRewardedAd() -> String:
	gameplay_stop()

	var result = await show_rewarded_ad()

	gameplay_start()

	if result is Dictionary and result.get("state", "") == "finished":
		return AD_REWARD_SUCCESS
	else:
		return AD_REWARD_FAILED
