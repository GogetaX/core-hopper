extends VBoxContainer


func _on_smart_button_buy_btn_pressed_with_price(currency: String, price: int) -> void:
	#Find Free Merge Slot
	var free_merge_slot = GlobalSave.FindFreeMergeSlot()
	if free_merge_slot == -1:
		print_debug("TODO: [notification] not enough slots. -1")
		return
	#Has Enough Money
	var cur_currency = GlobalSave.GetCurrency(currency)
	if price > cur_currency:
		print_debug("TODO: [Notification] not enough currency")
		return
	GlobalSave.RemoveCurrency(currency,price)
	
	#Create Bot
	var new_bot = GlobalSave.CreateSimpleBot()
	new_bot.merge_slot_id = free_merge_slot
	#Store bot to bot_db
	GlobalSave.StoreUpdateBotData(new_bot)
	
	#Milestone: first_bot (Own your first digging bot.)
	GlobalSave.SetMilestoneToCompleted("first_bot")
	
	#Save all
	GlobalSave.SyncSave()
	
func MergeItemBasedOnSlot(slot_num):
	return $MergePanel/MergeContainer.get_child(slot_num)
	
