extends Node

const ACTIVE_DRAG_AFTER_DISTANCE = 30

var merge_drag_at_other_merge_slot:MergeItemClass= null
var cur_dragging_node = null


#On what kind of node the drag is in
var cur_drag_data = {}

var top_currency_node_coin = null
var top_currency_node_energy = null
var top_currency_node_crystal = null

func CurrencyToIcon(currency_str:String):
	match currency_str:
		"coins":
			return preload("res://art/currency/coin.png")
		_:
			print_debug("Unknown currency: ",currency_str)
	return null

func SecondsToPrettyTimeString(total_seconds: int) -> String:
	total_seconds = max(0, total_seconds)

	var hours := total_seconds / 3600.0
	var minutes := (total_seconds % 3600) / 60.0
	var seconds := int(total_seconds % 60)

	var parts: Array[String] = []

	if hours > 0:
		parts.append("%dh" % hours)
	if minutes > 0:
		parts.append("%dm" % minutes)
	if seconds > 0 or parts.is_empty():
		parts.append("%ds" % seconds)

	return " ".join(parts)

func FloatToStr(value:float,decimals:float = 0.01):
	return str(snapped(value,decimals))
	
func CurrencyToString(value: float) -> String:
	var abs_value := absf(value)
	var _sign = "-" if value < 0.0 else ""

	if abs_value < 1000.0:
		return _sign + str(int(round(abs_value)))

	var suffixes := ["K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]
	var idx := -1
	var short_value := abs_value

	while short_value >= 1000.0 and idx < suffixes.size() - 1:
		short_value /= 1000.0
		idx += 1

	var decimals := 0
	if short_value < 10.0:
		decimals = 2
	elif short_value < 100.0:
		decimals = 1

	var formatted := "%.*f" % [decimals, short_value]

	if "." in formatted:
		while formatted.ends_with("0"):
			formatted = formatted.left(formatted.length() - 1)
		if formatted.ends_with("."):
			formatted = formatted.left(formatted.length() - 1)

	return _sign + formatted + suffixes[idx]
