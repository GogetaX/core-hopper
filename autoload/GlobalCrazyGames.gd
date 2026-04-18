extends Node

const AD_REWARD_SUCCESS = "SUCCESS"
const AD_REWARD_FAILED = "FAILED"

signal sdk_ready

var is_ready := false

var _last_uploaded_json := ""
var _save_queued := false


func InitCrazyGames():
	if OS.has_feature("crazygames"):
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

func QueueCrazySave() -> void:
	if !OS.has_feature("crazygames"):
		return
	if !GlobalCrazyGames.is_ready:
		return
	if _save_queued:
		return

	_save_queued = true
	await get_tree().create_timer(0.75).timeout
	_save_queued = false
	FlushCrazySave()

func FlushCrazySave() -> void:
	if !OS.has_feature("crazygames"):
		return
	if !GlobalCrazyGames.is_ready:
		return

	var json = JSON.stringify(GlobalSave.save_data)

	if json == _last_uploaded_json:
		return

	CrazyGames.Data.data_set_item("save_data", json)
	_last_uploaded_json = json

func LoadFromCrazyGames() -> bool:
	if !OS.has_feature("crazygames"):
		return false
	if !GlobalCrazyGames.is_ready:
		return false
	if !CrazyGames.Data.data_has_key("save_data"):
		return false

	var raw := str(CrazyGames.Data.data_get_item("save_data"))
	var parsed = JSON.parse_string(raw)

	if typeof(parsed) == TYPE_DICTIONARY:
		GlobalSave.save_data = parsed
		_last_uploaded_json = raw
		return true

	return false
