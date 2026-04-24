extends Node

const ACTIVE_DRAG_AFTER_DISTANCE = 30

var merge_drag_at_other_merge_slot:MergeItemClass= null
var cur_dragging_node = null
var chest_btn_node = null


#On what kind of node the drag is in
var cur_drag_data = {}

var top_currency_node_coin = null
var top_currency_node_energy = null
var top_currency_node_crystal = null
var top_currency_node_dust = null
var mouse_at_sell_node : MergeSellClass = null

var progress_menu_show_tab = ""

var last_skill_key_selected : String = ""
var top_bar_y_pos = 0.0

func _ready() -> void:
	GlobalSignals.DataSaved.connect(SyncData)
	#This is just a test
	
func SyncData():
	#here i test some stats that updating:
	#eg. GlobalStats.GetBossDamageMultiplier()
	return
	
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

func GetIconFromStr(icon_str:String)->Texture2D:
	return load("res://data/icons/"+icon_str+".tres")

func GenerateGameVersion()->String:
	#Build v2.4.0-Final
	#© 2026 CORE HOPPER STUDIOS
	var version = ProjectSettings.get_setting("application/config/version")
	var for_platform = OS.get_name()
	if OS.has_feature("crazygames"):
		for_platform = "CrazyGames"
	return "Build v"+version+"-BETA\n© 2026 CORE HOPPER STUDIOS\n"+for_platform+" Version"
	
func FormatNumberWithCommas(value) -> String:
	var is_negative := false
	var text := str(value)

	if text.begins_with("-"):
		is_negative = true
		text = text.substr(1)

	var parts := text.split(".")
	var int_part := parts[0]
	var decimal_part := ""
	if parts.size() > 1:
		decimal_part = "." + parts[1]

	var result := ""
	var count := 0

	for i in range(int_part.length() - 1, -1, -1):
		result = int_part[i] + result
		count += 1
		if count % 3 == 0 and i > 0:
			result = "," + result

	if is_negative:
		result = "-" + result

	return result + decimal_part
