@tool
extends Control
class_name SmartBuyBtn

signal BtnPressedWithPrice(currency:String,price:int)
signal OnPressed()

@export_enum("NO_PRICE","WITH_PRICE") var btn_type := "NO_PRICE":
	set(value):
		btn_type = value
		if is_node_ready():
			SyncTool()
	get:
		return btn_type
		
@export_enum("coins","crystals","energy") var currency_type := "coins":
	set(value):
		currency_type = value
		if is_node_ready():
			SyncTool()
	get:
		return currency_type

@export var buy_btn_title := "NEW UNIT":
	set(value):
		buy_btn_title = value
		if is_node_ready():
			SyncTool()
	get:
		return buy_btn_title

@export_enum("WHITE","GOLD","PURPLE","BLUE","DISABLED","TAB_BG","ORANGE") var panel_color := "PURPLE":
	set(value):
		panel_color = value
		if is_node_ready():
			SyncTool()
	get:
		return panel_color

@export var price_text := "150K AU":
	set(value):
		price_text = value
		if is_node_ready():
			SyncTool()
	get:
		return price_text
		
@export var price_int :int = 25:
	set(value):
		price_int = value
		if is_node_ready():
			_ready()
	get:
		return price_int

var _disabled_because_of_price = false

var already_inited = false
func _ready() -> void:
	SyncTool()
	if !Engine.is_editor_hint():
		
		CheckForCurrency()
		if !already_inited:
			GlobalBtn.AddBtnPress(self)
			GlobalBtn.AddBtnMouseInOut(self,[$NO_PRICE,$WITH_PRICE])
			GlobalBtn.BtnPress.connect(OnBtnPressed)
			GlobalSignals.DataSaved.connect(CheckForCurrency)
			already_inited = true

func SyncTool():
	$NO_PRICE.visible = false
	$WITH_PRICE.visible = false
	match btn_type:
		"NO_PRICE":
			$NO_PRICE.visible = true
		"WITH_PRICE":
			$WITH_PRICE.visible = true
			match currency_type:
				"coins":
					$WITH_PRICE/HBoxContainer/VList/SmartPanel/HBoxContainer/CurrencyIcon.icon_type = "COIN_SMALL"
				"crystals":
					$WITH_PRICE/HBoxContainer/VList/SmartPanel/HBoxContainer/CurrencyIcon.icon_type = "CRYSTAL_SMALL"
				"energy":
					$WITH_PRICE/HBoxContainer/VList/SmartPanel/HBoxContainer/CurrencyIcon.icon_type = "ENERGY_SMALL"
			
	$NO_PRICE/Label.text = buy_btn_title
	$WITH_PRICE/HBoxContainer/Label.text = buy_btn_title
	
	$NO_PRICE.panel_color = panel_color
	$WITH_PRICE.panel_color = panel_color
	
	$NO_PRICE/Label.self_modulate = $NO_PRICE.GetBorderColor()
	$WITH_PRICE/HBoxContainer/Label.self_modulate = $WITH_PRICE.GetBorderColor()
	
	$WITH_PRICE/HBoxContainer/VList/SmartPanel.panel_color = panel_color
	$WITH_PRICE/HBoxContainer/VList/SmartPanel/HBoxContainer/value_str.text = price_text

func CheckForCurrency():
	if btn_type == "WITH_PRICE":
		var cur_currency = GlobalSave.GetCurrency(currency_type)
		if cur_currency < price_int:
			modulate = GlobalColor.PRICE_DISABLED_COLOR
			_disabled_because_of_price = true
		else:
			modulate = Color.WHITE
			_disabled_because_of_price = false

	
	
func ShowOnly(show_btn:Control):
	for x in get_children():
		if x != show_btn:
			x.visible = false
	show_btn.visible = true
	
func OnBtnPressed(btn_node:Control):
	if btn_node != self:
		return
	if _disabled_because_of_price:
		return
	GlobalBtn.AnimateBtnPressed($NO_PRICE)
	GlobalBtn.AnimateBtnPressed($WITH_PRICE)
	match btn_type:
		"WITH_PRICE":
			BtnPressedWithPrice.emit(currency_type,price_int)
		"NO_PRICE":
			OnPressed.emit()
	
func GetCoinGlobalPos():
	return $WITH_PRICE/HBoxContainer/VList/SmartPanel/HBoxContainer/CurrencyIcon.GetCoinCenterPos()
