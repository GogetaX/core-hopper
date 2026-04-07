extends VBoxContainer
class_name UpgradeItemClass

var cur_key := ""
var cur_data := {}

func _ready() -> void:
	GlobalSignals.DataSaved.connect(UpdateCurItem)
	
func UpdateCurItem():
	InitUpgradeItem(cur_key,cur_data)
	

func InitUpgradeItem(key:String,data:Dictionary):
	cur_key = key
	cur_data = data
	print(cur_data)
	#Colors
	$SmartPanel.panel_color = GlobalColor.SkillUpgradeTextToColor(cur_data.group)
	$SmartPanel/VList/HList/IconBG.panel_color = GlobalColor.SkillUpgradeTextToColor(cur_data.group)
	$SmartPanel/VList/HList2/VList/per_level_hint.hash_tag_color = GlobalColor.SkillUpgradeTextToColor(cur_data.group)
	$SmartPanel/VList/HList/VList/HList/Skilllevel.hash_tag_color = GlobalColor.SkillUpgradeTextToColor(cur_data.group)
	$SmartPanel/VList/SmartButtonBuy.panel_color = GlobalColor.SkillUpgradeTextToColor(cur_data.group)
	#Data
	$SmartPanel/VList/HList/VList/skill_title.text = cur_data.title
	$SmartPanel/VList/HList/VList/HList/Skilllevel.text = "LV "+str(int(cur_data.level))
	$SmartPanel/VList/SmartButtonBuy.price_int = GlobalStats.GetUpgradeCost(cur_key)
	$SmartPanel/VList/SmartButtonBuy.buy_btn_title = "UPGRADE"
	$SmartPanel/VList/SmartButtonBuy.price_text = Global.CurrencyToString(GlobalStats.GetUpgradeCost(cur_key))
	
	#Icons
	$SmartPanel/VList/HList/IconBG.icon = Global.GetIconFromStr(cur_data.icon)
	$SmartPanel/IconBG.texture = Global.GetIconFromStr(cur_data.icon)
	
	#Smart cur_value display
	var cur_value = GlobalStats.GetUpgradeValue(cur_key)
	var next_level_value = GlobalStats.GetUpgradeValue(cur_key,1)
	var diff_value = next_level_value - cur_value
	
	$SmartPanel/VList/HList2/cur_value.text = "x"+Global.FloatToStr(cur_value)
	$SmartPanel/VList/HList2/VList/per_level_hint.text = "+"+Global.FloatToStr(diff_value*100.0).pad_decimals(0)+"%"
	
	match cur_key:
		"tap_damage":
			$SmartPanel/VList/HList2/cur_value.text = Global.CurrencyToString(GlobalStats.GetTapBaseDamageFromUpgradeLevel(cur_data.level)) + " DPT"
		"offline_efficiency":
			$SmartPanel/VList/HList2/cur_value.text = Global.SecondsToPrettyTimeString(GlobalOfflineProgress.GetOfflineCapSeconds())
func _on_smart_button_buy_btn_pressed_with_price(currency: String, price: int) -> void:
	GlobalSave.RemoveCurrency(currency,price)
	cur_data.level = int(cur_data.level + 1)
	var group_list = cur_data.group.split(",")
	for x in group_list:
		GlobalDailyQuest.RegisterUpgradeBought(cur_key, x)
	
	var cur_milestone_list = GlobalMilestone.GetMilestoneFromTargetTypeArray("upgrade_level")
	if !cur_milestone_list.is_empty():
		for x in cur_milestone_list:
			if x.data.target_key == cur_key && !GlobalSave.IsMilestoneCompleted(x.id):
				if x.data.target_value <= cur_data.level:
					GlobalSave.SetMilestoneToCompleted(x.id)
			
	GlobalSave.SyncSave()
