extends Control

@onready var stat_item = preload("res://scenes/components/bot_stat.tscn")

var cur_data = {}

func _ready() -> void:
	if !OS.is_debug_build():
		$BotStatInfo/VList/HList/PlusLvlBot.visible = false

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
	var bot_stat_dps = GlobalStats.GetBotFinalDPSWithGlobalAndStats(bot_data,false,false,true)
	$BotStatInfo/VList/HFlow/BotStat_DPS.top_value = Global.CurrencyToString(bot_stat_dps)
	$BotStatInfo/VList/HFlow/BotStat_SPD.top_value = str(snapped(GlobalStats.GetBotFinalDigSpeed(bot_data.level),0.01))
	$BotStatInfo/VList/SmartPanel/rarity.hash_tag_color = GlobalColor.BotRankToColor(bot_data.rank)

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
		var dps_against_boss = GlobalStats.GetBotFinalDPSWithGlobalAndStats(bot_data,false,true,true)
		if dps_against_boss != bot_stat_dps:
			var s = stat_item.instantiate() as BotStatItemClass
			$BotStatInfo/VList/AdditionalStats.add_child(s)
			s.top_value = Global.CurrencyToString(dps_against_boss)
			s.stat_name = "BOSS DPS"
			s.icon = load("res://art/skills/boss_damage.tres")
			s.panel_color = "GOLD"
			
	#Init Sell Price
	var sell_price = GlobalStats.GetBotSellValue(bot_data.level)
	$BotStatInfo/VList/HList/SellBotBtn.price_text = Global.CurrencyToString(sell_price)
	$BotStatInfo/VList/HList/SellBotBtn.price_int = sell_price
			
func _on_v_list_resized() -> void:
	var max_y = $BotStatInfo/VList.get_minimum_size().y
	$BotStatInfo.custom_minimum_size.y = max_y + 35
	$BotStatInfo.size.y = $BotStatInfo.custom_minimum_size.y

	
func _on_close_info_btn_on_pressed() -> void:
	GlobalMusic.SFX_UIBack()
	GlobalSignals.CloseCurPopup.emit()


func _on_sell_bot_btn_btn_pressed_with_price(currency: String, price: int) -> void:
	GlobalSave.AddCurrency(currency,price)
	GlobalSave.RemoveBotByID(cur_data.bot_uid)
	GlobalSave.SyncSave()
	GlobalSignals.CloseCurPopup.emit()


func _on_plus_lvl_bot_on_pressed() -> void:
	GlobalSave.LevelUpBotFromUID(cur_data.bot_uid,1)
	InitBotInfo(cur_data)
	GlobalSave.SyncSave()
