@tool
extends Control
class_name RewardCurrencyClass

@export_enum("COINS","CRYSTALS","ENERGY") var currency_type := "COINS":
	set(value):
		currency_type = value
		if is_node_ready():
			_ready()
			
	get:
		return currency_type
		
@export var amount_str := "123.5K"


func _ready() -> void:
	match currency_type:
		"COINS":
			$SmartPanel/VList/HList/CurrencyIcon.icon_type = "COIN_SMALL"
			$SmartPanel/VList/value.theme_type_variation = "LabelTitle_Blue"
		"CRYSTALS":
			$SmartPanel/VList/HList/CurrencyIcon.icon_type = "CRYSTAL_BIG_ANIMATED"
			$SmartPanel/VList/value.theme_type_variation = "LabelTitle_Purple"
		"ENERGY":
			$SmartPanel/VList/HList/CurrencyIcon.icon_type = "ENERGY_SMALL_ANIMATED"
			$SmartPanel/VList/value.theme_type_variation = "LabelTitle_Gold"
	$SmartPanel/VList/value.text = amount_str

func GetCurrencyCenterGlobalPos():
	return $SmartPanel/VList/HList/CurrencyIcon.global_position + ($SmartPanel/VList/HList/CurrencyIcon.size / 2)
