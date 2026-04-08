extends Control

@onready var stat_item = preload("res://scenes/components/bot_stat.tscn")

var cur_data = {}

func InitBotInfo(data):
	cur_data = data
	var bot_data = GlobalSave.GetBotDataFromUID(cur_data.bot_uid)
	if bot_data.is_empty():
		$BotStatInfo.visible = false
		return
	$BotStatInfo.visible = true
	$BotStatInfo/VList/SmartPanel/BotImage.SetImageFromBotNum(bot_data.level)
	$BotStatInfo/VList/SmartPanel/rarity.text = GlobalBotStats.GetRankTitle(bot_data.rank)
	$BotStatInfo/VList/SmartPanel/bot_level.text = "LVL "+str(bot_data.level).pad_decimals(0)
	$BotStatInfo/VList/HFlow/BotStat_DPS.top_value = Global.CurrencyToString(GlobalStats.GetBotFinalDps(bot_data.level))
	$BotStatInfo/VList/HFlow/BotStat_SPD.top_value = str(snapped(GlobalStats.GetBotFinalDigSpeed(bot_data.level),0.01))
	$BotStatInfo/VList/SmartPanel/rarity.hash_tag_color = GlobalColor.BotRankToColor(bot_data.rank)
	print(bot_data)
	#Clear additional stats
	for x in $BotStatInfo/VList/AdditionalStats.get_children():
		x.queue_free()
	if bot_data.stats.is_empty():
		$BotStatInfo/VList/Label3.visible = false
	else:
		for x in bot_data.stats:
			var s = stat_item.instantiate() as BotStatItemClass
			$BotStatInfo/VList/AdditionalStats.add_child(s)
			var val_str = GlobalBotStats.GetStatDescription(x,bot_data.stats[x])
			s.top_value = val_str
			var stat_data = GlobalBotStats.GetStatData(x)
			s.stat_name = stat_data.title.to_upper()
			s.icon = GlobalBotStats.GetIcon(stat_data.icon)
			s.panel_color = "GOLD"
			
func _on_v_list_resized() -> void:
	var max_y = $BotStatInfo/VList.get_minimum_size().y
	$BotStatInfo.custom_minimum_size.y = max_y + 35
	$BotStatInfo.size.y = $BotStatInfo.custom_minimum_size.y

	
func _on_close_info_btn_on_pressed() -> void:
	GlobalSignals.CloseCurPopup.emit()
