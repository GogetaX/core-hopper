extends Control
class_name UpgradeCostItemClass

var _has_enough = false

func InitCost(currency:String,value:int):
	var currency_color = GlobalColor.CurrencyToColorStr(currency)
	$SmartPanel.panel_color = currency_color
	$HList/CurrencyIcon.ShowSmallCurrency(currency)
	$HList/cur_value.text = Global.CurrencyToString(value)
	var max_value = GlobalSave.GetCurrency(currency)
	$HList/max_value.text = Global.CurrencyToString(max_value)
	$HList/cur_value.hash_tag_color = currency_color
	$HList/max_value.hash_tag_color = currency_color
	$HList/ProgressHashTag2.hash_tag_color = currency_color
	
	if max_value < value:
		_has_enough = false
		$HList/cur_value.hash_tag_color = "RED"
	else:
		_has_enough = true
	await get_tree().process_frame
	_on_h_list_resized()
	

func HasEnough():
	return _has_enough
	
func _on_h_list_resized() -> void:
	var max_x = $HList.get_minimum_size().x
	custom_minimum_size.x = max_x + 50
	size.x = custom_minimum_size.x
