extends Node

var admob_plugin : Admob = null

func IsRewardedReady():
	var is_ready = false
	if admob_plugin:
		if admob_plugin.is_rewarded_ad_loaded():
			is_ready = true
			
	return is_ready
	
func ShowRewarded():
	if IsRewardedReady():
		admob_plugin.show_rewarded_ad()
	return false
