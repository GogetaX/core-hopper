extends Control

func _ready() -> void:
	GlobalSignals.SetTopSubTitle.connect(TopSubTitleSync)
	GlobalSignals.OpenCloseSettingMenu.connect(OnOpenCloseSettingMenu)
	GlobalSignals.OnTabBtnpressed.connect(OnTabPressed)
	$HBoxContainer/CloseSettingMenu.visible = false
	Global.top_currency_node_coin = $HBoxContainer/VList/CurrencyCointainer/total_coins/HList/CurrencyIcon
	Global.top_currency_node_crystal = $HBoxContainer/VList/CurrencyCointainer/total_crystals/HList/CurrencyIcon
	Global.top_currency_node_energy = Global.top_currency_node_coin
func OnTabPressed(_tab_btn:ButtonTabClass):
	OnOpenCloseSettingMenu(false)
	
func TopSubTitleSync(sub_title:String):
	$HBoxContainer/VBoxContainer/HBoxContainer/sub_title.text = sub_title

func OnOpenCloseSettingMenu(is_opened:bool):
	if is_opened:
		$HBoxContainer/SettingButton.visible = false
		$HBoxContainer/CloseSettingMenu.visible = true
		$HBoxContainer/VList/CurrencyCointainer.visible = false
	else:
		
		$HBoxContainer/SettingButton.visible = true
		$HBoxContainer/CloseSettingMenu.visible = false
		$HBoxContainer/VList/CurrencyCointainer.visible = true
	
func _on_setting_button_btn_pressed() -> void:
	GlobalSignals.OpenCloseSettingMenu.emit(true)
	


func _on_close_setting_menu_btn_pressed() -> void:
	GlobalSignals.OpenCloseSettingMenu.emit(false)
	$HBoxContainer/SettingButton.visible = true
	$HBoxContainer/CloseSettingMenu.visible = false
	$HBoxContainer/CurrencyCointainer.visible = true
