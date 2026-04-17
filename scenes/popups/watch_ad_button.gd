@tool
extends Control
class_name WatchAdClass

signal WatchAdOpenedOnce(watch_ad_id:String)


@export_enum("WHITE","GOLD","PURPLE","BLUE","DISABLED","TAB_BG","ORANGE") var panel_color := "PURPLE":
	set(value):
		panel_color = value
		if is_node_ready():
			_ready()
	get:
		return panel_color
		
@export var icon_big : Texture2D = null:
	set(value):
		icon_big = value
		if is_node_ready():
			_ready()
	get:
		return icon_big
		
@export var ad_title := "Instant Hyper-Dig":
	set(value):
		ad_title = value
		if is_node_ready():
			_ready()
	get:
		return ad_title

@export var ad_subtitle := "30M RESOURCE CACHE":
	set(value):
		ad_subtitle = value
		if is_node_ready():
			_ready()
	get:
		return ad_subtitle
		
@export var times_per_day := 1:
	set(value):
		times_per_day = value
		if is_node_ready():
			_ready()
	get:
		return times_per_day

var reward_list = []

func _ready() -> void:
	$SmartPanel/VList/HList/IconBG.panel_color = panel_color
	$SmartPanel/VList/HList/VList/ad_subtitle.hash_tag_color = panel_color
	$SmartPanel/VList/WatchAdBtn.panel_color = panel_color
	$SmartPanel/VList/HList/IconBG.icon = icon_big
	if times_per_day > 0:
		$SmartPanel/VList/HList/VList/ad_title.text = ad_title + " ("+str(times_per_day).pad_decimals(0)+")"
	else:
		$SmartPanel/VList/HList/VList/ad_title.text = ad_title
	$SmartPanel/VList/HList/VList/ad_subtitle.text = ad_subtitle
	if !Engine.is_editor_hint():
		if times_per_day > 0:
			$SmartPanel/VList/WatchAdBtn.SetDisabled(false)
			$SmartPanel/VList/HList/VList/ad_title.text = ad_title + " ("+str(times_per_day).pad_decimals(0)+")"
		else:
			$SmartPanel/VList/WatchAdBtn.SetDisabled(true)
func AddRewards(_rewards):
	reward_list = _rewards
	
func _on_watch_ad_btn_on_press() -> void:
	var reward = await GlobalCrazyGames.OnWatchRewardedAd()
	if reward != GlobalCrazyGames.AD_REWARD_SUCCESS:
		return
	for x in reward_list:
		if x.has("coins") || x.has("crystals") || x.has("dust") || x.has("energy"):
			for key in x.keys():
				GlobalSignals.AddNotification.emit({"type":"TEXT","description":"+"+str(x[key]).pad_decimals(0)+" "+key.to_upper(),"color":"BLUE"})
				GlobalSave.AddCurrency(key,x[key])
		elif x.has("random_relic_crate"):
			var relic_create_amount = x.random_relic_crate
			for amount in relic_create_amount:
				var relic_id = GlobalRelicDb.GetRandomRelicID()
				var relic_data = GlobalRelicDb.GetRelicDataByID(relic_id)
				GlobalSignals.AddNotification.emit({"type":"TEXT","description":"+RELIC\n"+relic_data.title,"color":"PURPLE"})
				GlobalRelicDb.AddOwnedRelic(relic_id)
		elif x.has("random_bot_level"):
			var bot_level = x.random_bot_level
			var bot_amount = x.amount
			for amount in bot_amount:
				GlobalSignals.AddNotification.emit({"type":"TEXT","description":"NEW BOT LV"+str(bot_level).pad_decimals(0) ,"color":"ORANGE"})
				var free_merge_slot = GlobalSave.FindFreeMergeSlot()
				var new_bot_data = GlobalSave.CreateSimpleBot()
				new_bot_data.merge_slot_id = free_merge_slot
				new_bot_data.level = bot_level
				#Store bot to bot_db
				GlobalSave.StoreUpdateBotData(new_bot_data)
		else:
			print_debug("Unknown: ",x)
	WatchAdOpenedOnce.emit(str(name))
	
		
