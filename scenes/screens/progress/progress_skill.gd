extends VBoxContainer
class_name UpgradeItemClass

var cur_key := ""
var cur_data := {}

func _ready() -> void:
	GlobalSignals.DataSaved.connect(UpdateCurItem)
	
func UpdateCurItem():
	InitUpgradeItem(cur_key,cur_data)
	

func InitUpgradeItem(key: String, data: Dictionary):
	cur_key = key
	cur_data = data

	# Colors
	$SmartPanel.panel_color = GlobalColor.SkillUpgradeTextToColor(cur_data.group)
	$SmartPanel/VList/HList/IconBG.panel_color = GlobalColor.SkillUpgradeTextToColor(cur_data.group)
	$SmartPanel/VList/HList2/VList/per_level_hint.hash_tag_color = GlobalColor.SkillUpgradeTextToColor(cur_data.group)
	$SmartPanel/VList/HList/VList/HList/Skilllevel.hash_tag_color = GlobalColor.SkillUpgradeTextToColor(cur_data.group)
	$SmartPanel/VList/SmartButtonBuy.panel_color = GlobalColor.SkillUpgradeTextToColor(cur_data.group)

	# Data
	$SmartPanel/VList/HList/VList/skill_title.text = cur_data.title
	$SmartPanel/VList/HList/VList/HList/Skilllevel.text = "LV " + str(int(cur_data.level))
	$SmartPanel/VList/SmartButtonBuy.price_int = GlobalStats.GetUpgradeCost(cur_key)
	$SmartPanel/VList/SmartButtonBuy.buy_btn_title = "UPGRADE"
	$SmartPanel/VList/SmartButtonBuy.price_text = Global.CurrencyToString(GlobalStats.GetUpgradeCost(cur_key))

	# Icons
	$SmartPanel/VList/HList/IconBG.icon = Global.GetIconFromStr(cur_data.icon)
	$SmartPanel/IconBG.texture = Global.GetIconFromStr(cur_data.icon)

	var effect_type := str(cur_data.get("effect_type", ""))
	var cur_value: float = 0.0
	var next_value: float = 0.0

	match effect_type:
		"tap_curve":
			cur_value = float(GlobalStats.GetTapBaseDamageFromUpgradeLevel(int(cur_data.level)))
			next_value = float(GlobalStats.GetTapBaseDamageFromUpgradeLevel(int(cur_data.level) + 1))

		_:
			cur_value = float(GlobalStats.GetUpgradeValue(cur_key))
			next_value = float(GlobalStats.GetUpgradeValue(cur_key, 1))

	var diff_value := next_value - cur_value

	$SmartPanel/VList/HList2/cur_value.text = _FormatUpgradeValue(cur_key, effect_type, cur_value)
	$SmartPanel/VList/HList2/VList/per_level_hint.text = _FormatUpgradePerLevelHint(cur_key, effect_type, diff_value, cur_data)
	
	
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
	
func _FormatUpgradeValue(upgrade_key: String, effect_type: String, value: float) -> String:
	match effect_type:
		"tap_curve":
			return Global.CurrencyToString(int(round(value))) + " DPT"

		"mult_pow":
			return "x" + Global.FloatToStr(value)

		"linear", "flat":
			if _ShouldUsePercentDisplay(upgrade_key, value):
				return "+" + str(int(round(value * 100.0))) + "%"
			return "+" + Global.FloatToStr(value)

		_:
			return Global.FloatToStr(value)


func _FormatUpgradePerLevelHint(upgrade_key: String, effect_type: String, diff_value: float, data: Dictionary) -> String:
	match effect_type:
		"tap_curve":
			return "+" + Global.CurrencyToString(int(round(diff_value))) + " DPT"

		"mult_pow":
			var effect_base := float(data.get("effect_base", 1.0))
			var per_level_percent := (effect_base - 1.0) * 100.0
			return "+" + str(int(round(per_level_percent))) + "% / LV"

		"linear", "flat":
			if _ShouldUsePercentDisplay(upgrade_key, diff_value):
				return "+" + str(int(round(diff_value * 100.0))) + "% / LV"
			return "+" + Global.FloatToStr(diff_value) + " / LV"

		_:
			return "+" + Global.FloatToStr(diff_value)


func _ShouldUsePercentDisplay(upgrade_key: String, value: float) -> bool:
	if upgrade_key in ["crit_chance", "crit_multiplier", "offline_efficiency"]:
		return true

	return abs(value) <= 1.0
