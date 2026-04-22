extends VBoxContainer

func _ready() -> void:
	GlobalSignals.DataSaved.connect(SyncData)
	SyncData()
	
func SyncData():
	#Set buy level
	var buy_level_data = GlobalStats.BuyBotData()
	$VList/BuyBotBtn.price_int = buy_level_data.price
	$VList/BuyBotBtn.price_text = Global.CurrencyToString(buy_level_data.price)
	$VList/BuyBotBtn.buy_btn_title = "NEW UNIT LV"+str(buy_level_data.level)
	
	#Set Daily Free bot limit
	var daily_limit = GlobalSave.GetDailyFreeBot()
	$VList/DailyFreeBot.buy_btn_title = "DAILY FREE BOT ("+str(daily_limit.amount).pad_decimals(0)+")"
	if daily_limit.amount > 0:
		$VList/DailyFreeBot.SetDisabled(false)
	else:
		$VList/DailyFreeBot.SetDisabled(true)
		
	$VList/DailyMythicBot.buy_btn_title = "DAILY FREE MYTHIC ("+str(daily_limit.mythic_amount).pad_decimals(0)+")"
	if daily_limit.mythic_amount > 0 && GlobalAds.IsRewardedReady():
		$VList/DailyMythicBot.SetDisabled(false)
	else:
		$VList/DailyMythicBot.SetDisabled(true)
	
	$VList/BuyBotBtn.sub_text = "Free bot in "+str(GlobalStats.GetFreeBotCountDown()-GlobalSave.save_data.progress.free_bot_count).pad_decimals(0)

func _on_smart_button_buy_btn_pressed_with_price(currency: String, price: int) -> void:
	#Find Free Merge Slot
	var free_merge_slot = GlobalSave.FindFreeMergeSlot()
	if free_merge_slot == -1:
		GlobalSignals.AddNotification.emit({"type":"TEXT","description":"No free slots available","color":"RED"})
		return
	#Has Enough Money
	var cur_currency = GlobalSave.GetCurrency(currency)
	if price > cur_currency:
		GlobalSignals.AddNotification.emit({"type":"TEXT","description":"Not enough coins","color":"RED"})
		return
	GlobalSave.RemoveCurrency(currency,price)
	
	#Create Bot
	var buy_bot_data = GlobalStats.BuyBotData()
	var new_bot = GlobalSave.CreateSimpleBot(GlobalStats.RollDirectBotBuyRank())
	new_bot.merge_slot_id = free_merge_slot
	new_bot.level = buy_bot_data.level
	if GlobalStats.HasChanceOfNextLevelBotOnBuy():
		new_bot.level += 1
	#Store bot to bot_db
	GlobalSave.StoreUpdateBotData(new_bot)
	
	#Milestone: first_bot (Own your first digging bot.)
	if GlobalSave.save_data.player_stats.total_bots_bought == 1:
		GlobalSave.SetMilestoneToCompleted("first_bot")
	
	#Check for Refund buying new bot chance
	if GlobalStats.GetRefundChestOnBuy():
		GlobalSave.AddCurrency(currency,price)
	
	#Save all
	GlobalSave.save_data.progress.free_bot_count += 1
	if GlobalStats.GetFreeBotCountDown()<= GlobalSave.save_data.progress.free_bot_count:
		GlobalSave.save_data.progress.free_bot_count = 0
		GlobalSave.save_data.daily_free_bot.amount += 1
	GlobalSave.SyncSave()
	
func MergeItemBasedOnSlot(slot_num):
	return $MergePanel/MergeContainer.get_child(slot_num)
	


func _on_daily_free_bot_on_pressed() -> void:
	var free_merge_slot = GlobalSave.FindFreeMergeSlot()
	if free_merge_slot == -1:
		GlobalSignals.AddNotification.emit({"type":"TEXT","description":"No free slots available","color":"RED"})
		return
		
	#Create Bot
	var buy_bot_data = GlobalStats.BuyBotData()
	var new_bot = GlobalSave.CreateSimpleBot(GlobalStats.RollDirectBotBuyRank())
	new_bot.merge_slot_id = free_merge_slot
	new_bot.level = buy_bot_data.level
	if GlobalStats.HasChanceOfNextLevelBotOnBuy():
		new_bot.level += 1
	#Store bot to bot_db
	GlobalSave.StoreUpdateBotData(new_bot,true)
	
	#Milestone: first_bot (Own your first digging bot.)
	if GlobalSave.save_data.player_stats.total_bots_bought == 1:
		GlobalSave.SetMilestoneToCompleted("first_bot")
	
	GlobalSave.save_data.daily_free_bot.amount -= 1
	#Save data
	GlobalSave.SyncSave()
	


func _on_daily_mythic_bot_on_press() -> void:
	var free_merge_slot = GlobalSave.FindFreeMergeSlot()
	if free_merge_slot == -1:
		GlobalSignals.AddNotification.emit({"type":"TEXT","description":"No free slots available","color":"RED"})
		return
		
	#Create Bot
	var buy_bot_data = GlobalStats.BuyBotData()
	var new_bot = GlobalSave.CreateSimpleBot(3)
	new_bot.merge_slot_id = free_merge_slot
	new_bot.level = buy_bot_data.level
	if GlobalStats.HasChanceOfNextLevelBotOnBuy():
		new_bot.level += 1
	#Store bot to bot_db
	GlobalSave.StoreUpdateBotData(new_bot,true)
	
	#Milestone: first_bot (Own your first digging bot.)
	if GlobalSave.save_data.player_stats.total_bots_bought == 1:
		GlobalSave.SetMilestoneToCompleted("first_bot")
	
	GlobalSave.save_data.daily_free_bot.mythic_amount -= 1
	#Save data
	GlobalSave.SyncSave()
