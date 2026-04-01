extends Control
class_name MilestoneCurrencyClass

func InitItem(currency_type:String,value:int):
	match currency_type:
		"coins":
			$HList/CurrencyIcon.icon_type = "COIN_SMALL"
		"crystals":
			$HList/CurrencyIcon.icon_type = "CRYSTAL_SMALL"
		"energy":
			$HList/CurrencyIcon.icon_type = "ENERGY_SMALL"
		_:
			print_debug("unknown currency reward: ",currency_type)
	$HList/value.text = Global.CurrencyToString(value)
