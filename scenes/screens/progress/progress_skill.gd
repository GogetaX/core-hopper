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
			$SmartPanel/VList/HList2/cur_value.text = Global.CurrencyToString(GlobalStats.GetTapDamage()) + " DPC"
func _on_smart_button_buy_btn_pressed_with_price(currency: String, price: int) -> void:
	GlobalSave.RemoveCurrency(currency,price)
	cur_data.level = int(cur_data.level + 1)
	GlobalSave.SyncSave()
