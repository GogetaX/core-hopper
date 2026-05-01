extends Control

@onready var used_for_item = preload("res://scenes/components/used_for_item.tscn")


func _ready() -> void:
	GlobalSignals.OnCurrencyTabPressed.connect(OnCurrencyTabPressed)
	SyncUsedFor()
	
func OnCurrencyTabPressed(_currency_tab:CurrencyTabClass):
	SyncUsedFor()
	
func _on_close_info_btn_on_pressed() -> void:
	GlobalSignals.CloseCurPopup.emit()


func UsedForSync() -> void:
	var y_max = $CurrencyInfo/VList/UsedFor/VList.get_minimum_size().y
	$CurrencyInfo/VList/UsedFor.custom_minimum_size.y = y_max+35
	await get_tree().process_frame
	$CurrencyInfo/VList/UsedFor.size.y = $CurrencyInfo/VList/UsedFor.custom_minimum_size.y

func SyncUsedFor():
	var cur_tab_selected = GetCurTabSelected()
	ClearUsedForTabs()
	match cur_tab_selected:
		"COINS":
			$CurrencyInfo/VList/Control/CurrencyIcon.icon_type = "COIN_BIG_ANIMATED"
			$CurrencyInfo/VList/currency_name.text = "COINS"
			$CurrencyInfo/VList/currency_name.hash_tag_color = "BLUE"
			$CurrencyInfo/VList/currency_value.text = Global.CurrencyToString(GlobalSave.GetCurrency("coins"))
			$CurrencyInfo/VList/currenc_description.text = "Main progression currency"
			AddUsedFor(load("res://art/bottom_bar/progress.tres"),"Progress","BLUE")
			AddHowToGet(load("res://art/bottom_bar/dig.tres"),"Earned from blocks","BLUE")
			AddHowToGet(load("res://art/bosses/status_boss.png"),"Earned from bosses","PURPLE")
		"CRYSTALS":
			$CurrencyInfo/VList/Control/CurrencyIcon.icon_type = "CRYSTAL_BIG_ANIMATED"
			$CurrencyInfo/VList/currency_name.text = "CRYSTALS"
			$CurrencyInfo/VList/currency_name.hash_tag_color = "PURPLE"
			$CurrencyInfo/VList/currency_value.text = Global.CurrencyToString(GlobalSave.GetCurrency("crystals"))
			$CurrencyInfo/VList/currenc_description.text = "Valuable upgrade currency"
			AddUsedFor(load("res://art/bottom_bar/skills.tres"),"Skill Tree","PURPLE")
			AddHowToGet(load("res://art/bottom_bar/dig.tres"),"Small chance from blocks","BLUE")
			AddHowToGet(load("res://art/bosses/status_boss.png"),"Bigger rewards from bosses","PURPLE")
		"DUST":
			$CurrencyInfo/VList/Control/CurrencyIcon.icon_type = "DUST_SMALL"
			$CurrencyInfo/VList/currency_name.text = "DUST"
			$CurrencyInfo/VList/currency_name.hash_tag_color = "GOLD"
			$CurrencyInfo/VList/currency_value.text = Global.CurrencyToString(GlobalSave.GetCurrency("dust"))
			$CurrencyInfo/VList/currenc_description.text = "Relic currency"
			AddUsedFor(load("res://art/skills/relic_find.tres"),"Relics","GOLD")
			AddHowToGet(load("res://art/bosses/status_boss.png"),"Earned from bosses","PURPLE")
		"ENERGY":
			$CurrencyInfo/VList/Control/CurrencyIcon.icon_type = "ENERGY_SMALL_ANIMATED"
			$CurrencyInfo/VList/currency_name.text = "ENERGY"
			$CurrencyInfo/VList/currency_name.hash_tag_color = "GOLD"
			$CurrencyInfo/VList/currency_value.text = Global.CurrencyToString(GlobalSave.GetCurrency("energy"))
			$CurrencyInfo/VList/currenc_description.text = "Utility / shop currency"
			AddUsedFor(load("res://art/bottom_bar/shop.tres"),"Shop","GOLD")
			
			AddHowToGet(load("res://art/skills/daily_quest_limit.tres"),"Earned from quests","BLUE")
			AddHowToGet(load("res://art/skills/daily_quest_limit.tres"),"Earned from milestones","ORANGE")
			AddHowToGet(load("res://art/bosses/status_boss.png"),"Earned from bosses","PURPLE")
			AddHowToGet(load("res://art/bottom_bar/dig.tres"),"Small chance from blocks","BLUE")
		_:
			print_debug("Unknown tab selected: ",cur_tab_selected)
			
func AddHowToGet(icon:Texture2D,desc:String,color_str:String)->void:
	var u = used_for_item.instantiate() as UsedForClass
	$CurrencyInfo/VList/HowToGet/VList.add_child(u)
	u.InitItem(icon,desc,color_str)
	
func AddUsedFor(icon:Texture2D,desc:String,color_str:String)->void:
	var u = used_for_item.instantiate() as UsedForClass
	$CurrencyInfo/VList/UsedFor/VList.add_child(u)
	u.InitItem(icon,desc,color_str)
	
func ClearUsedForTabs():
	for x in $CurrencyInfo/VList/UsedFor/VList.get_children():
		if x is UsedForClass:
			x.queue_free()
	
	for x in $CurrencyInfo/VList/HowToGet/VList.get_children():
		if x is UsedForClass:
			x.queue_free()
			
func GetCurTabSelected():
	
	for x in $CurrencyInfo/VList/TopTabBar.get_children():
		if x.IsSelected():
			return x.currency_type
	return ""


func SyncHowToGet() -> void:
	var y_max = $CurrencyInfo/VList/HowToGet/VList.get_minimum_size().y
	$CurrencyInfo/VList/HowToGet.custom_minimum_size.y = y_max+35
	await get_tree().process_frame
	$CurrencyInfo/VList/HowToGet.size.y = $CurrencyInfo/VList/HowToGet.custom_minimum_size.y


func OnPopupResize() -> void:
	var max_y = $CurrencyInfo/VList.get_minimum_size().y
	$CurrencyInfo.custom_minimum_size.y = max_y + 35
	await get_tree().process_frame
	$CurrencyInfo.size.y = $CurrencyInfo.custom_minimum_size.y
	$CurrencyInfo.position.y = 50
