@tool
extends Control

@export_enum("WHITE","GOLD","PURPLE","BLUE","DISABLED","TAB_BG","ORANGE") var panel_color := "PURPLE":
	set(value):
		panel_color = value
		if is_node_ready():
			_ready()
	get:
		return panel_color
		
@export var item_name := "Handful of Gems":
	set(value):
		item_name = value
		if is_node_ready():
			_ready()
	get:
		return item_name

@export var item_subname := "500 Crystals + 50 Bonus":
	set(value):
		item_subname = value
		if is_node_ready():
			_ready()
	get:
		return item_subname
		
@export var item_price := "$1.99":
	set(value):
		item_price = value
		if is_node_ready():
			_ready()
	get:
		return item_price
		
@export var show_most_popular := false:
	set(value):
		show_most_popular = value
		if is_node_ready():
			_ready()
	get:
		return show_most_popular
		
@export var crystal_icon : Texture2D = null:
	set(value):
		crystal_icon = value
		if is_node_ready():
			_ready()
	get:
		return crystal_icon
		
@export_enum("REAL_MONEY","crystals","energy","coins") var currency_type := "REAL_MONEY":
	set(value):
		currency_type = value
		if is_node_ready():
			_ready()
	get:
		return currency_type
		
@export_enum("crystals","energy","coins") var get_currency_type := "crystals"
@export var get_currency_value := 2000
		
func _ready() -> void:
	$SmartPanel/HList/IconBG.panel_color = panel_color
	$SmartPanel/HList/BuyBtn.panel_color = panel_color
	$SmartPanel/HList/VList/item_title.text = item_name
	$SmartPanel/HList/VList/item_subtitle.text = item_subname
	$SmartPanel/HList/BuyBtn.buy_btn_title = item_price
	$MostPopular.visible = show_most_popular
	$SmartPanel.panel_color = panel_color
	$SmartPanel/HList/IconBG.icon = crystal_icon
	
	match currency_type:
		"REAL_MONEY":
			$SmartPanel/HList/BuyBtn.btn_type = "NO_PRICE"
			$SmartPanel/HList/BuyBtn.custom_minimum_size.x = 200
		_:
			$SmartPanel/HList/BuyBtn.btn_type = "WITH_PRICE"
			$SmartPanel/HList/BuyBtn.buy_btn_title = "BUY"
			$SmartPanel/HList/BuyBtn.custom_minimum_size.x = 350
			$SmartPanel/HList/BuyBtn.currency_type = currency_type
			if !Engine.is_editor_hint():
				$SmartPanel/HList/BuyBtn.price_text =  Global.CurrencyToString(int(item_price))
			else:
				$SmartPanel/HList/BuyBtn.price_text = item_price
			$SmartPanel/HList/BuyBtn.price_int = int(item_price)


func _on_buy_btn_btn_pressed_with_price(currency: String, price: int) -> void:
	GlobalSave.RemoveCurrency(currency,price)
	GlobalSave.AddCurrency(get_currency_type,get_currency_value)
	GlobalSignals.ShowCurrencyAnimation.emit($SmartPanel/HList/BuyBtn.GetCoinGlobalPos(),get_currency_type,int(get_currency_value/50.0))
	GlobalSave.SyncSave()
