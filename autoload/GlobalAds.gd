extends Node

#Ads Configuration
const SKIP_REWARDED_VIDS = false

signal rewarded_ready_changed(is_ready: bool)
signal rewarded_reward_earned(reward_type: String, reward_amount: int)

var admob_plugin: Admob = null
var _rewarded_ad_id: String = ""
var _is_initialized: bool = false


func Setup(plugin: Admob) -> void:
	admob_plugin = plugin
	
	if admob_plugin == null:
		push_error("GlobalAds.Setup: admob_plugin is null")
		return
	
	# Init
	if !admob_plugin.initialization_completed.is_connected(_OnAdmobInitialized):
		admob_plugin.initialization_completed.connect(_OnAdmobInitialized)
	
	# Rewarded load
	if !admob_plugin.rewarded_ad_loaded.is_connected(_OnRewardedLoaded):
		admob_plugin.rewarded_ad_loaded.connect(_OnRewardedLoaded)
	
	if !admob_plugin.rewarded_ad_failed_to_load.is_connected(_OnRewardedFailedToLoad):
		admob_plugin.rewarded_ad_failed_to_load.connect(_OnRewardedFailedToLoad)
	
	# Reward callback
	if !admob_plugin.rewarded_ad_user_earned_reward.is_connected(_OnRewardedEarned):
		admob_plugin.rewarded_ad_user_earned_reward.connect(_OnRewardedEarned)
	
	# Fullscreen close
	if !admob_plugin.rewarded_ad_dismissed_full_screen_content.is_connected(_OnRewardedDismissed):
		admob_plugin.rewarded_ad_dismissed_full_screen_content.connect(_OnRewardedDismissed)
	
	# Optional fail-to-show
	if admob_plugin.has_signal("rewarded_ad_failed_to_show_full_screen_content"):
		if !admob_plugin.rewarded_ad_failed_to_show_full_screen_content.is_connected(_OnRewardedFailedToShow):
			admob_plugin.rewarded_ad_failed_to_show_full_screen_content.connect(_OnRewardedFailedToShow)
	
	admob_plugin.initialize()


func _OnAdmobInitialized(_status_data) -> void:
	_is_initialized = true
	LoadRewarded()


func LoadRewarded() -> void:
	if admob_plugin == null:
		return
	if !_is_initialized:
		return
	if _rewarded_ad_id != "":
		return
	var request := LoadAdRequest.new()
	request.set_ad_unit_id("ca-app-pub-6225081745698787/4585397866")
	admob_plugin.load_rewarded_ad(request)


func IsRewardedReady() -> bool:
	if SKIP_REWARDED_VIDS:
		return true
	return _rewarded_ad_id != ""


func ShowRewarded() -> bool:
	if SKIP_REWARDED_VIDS:
		await get_tree().create_timer(0.1).timeout
		rewarded_reward_earned.emit("reward",1)
		return true
		
	if admob_plugin == null:
		return false
	
	if _rewarded_ad_id == "":
		return false
	
	else:
		admob_plugin.show_rewarded_ad(_rewarded_ad_id)
	return true


func _OnRewardedLoaded(ad_info, _response_info) -> void:
	_rewarded_ad_id = ad_info.get_ad_id()
	rewarded_ready_changed.emit(true)
	print("Rewarded loaded: ", _rewarded_ad_id)


func _OnRewardedFailedToLoad(_ad_info, error_data) -> void:
	_rewarded_ad_id = ""
	rewarded_ready_changed.emit(false)
	print("Rewarded failed to load: ", error_data)


func _OnRewardedEarned(_ad_info, reward_data) -> void:
	var reward_type := ""
	var reward_amount := 0
	
	if reward_data != null:
		if reward_data.has_method("get_type"):
			reward_type = str(reward_data.get_type())
		elif reward_data.has_method("get_reward_type"):
			reward_type = str(reward_data.get_reward_type())
		
		if reward_data.has_method("get_amount"):
			reward_amount = int(reward_data.get_amount())
		elif reward_data.has_method("get_reward_amount"):
			reward_amount = int(reward_data.get_reward_amount())
	
	print("Reward earned: ", reward_type, " x", reward_amount)
	rewarded_reward_earned.emit(reward_type, reward_amount)


func _OnRewardedDismissed(_ad_info) -> void:
	_rewarded_ad_id = ""
	rewarded_ready_changed.emit(false)
	LoadRewarded()


func _OnRewardedFailedToShow(_ad_info, error_data) -> void:
	print("Rewarded failed to show: ", error_data)
	_rewarded_ad_id = ""
	rewarded_ready_changed.emit(false)
	LoadRewarded()
