extends Node

const COLOR_TEXT_PURPLE = Color("F2D6FF")
const COLOR_BORDER_PURPLE = Color("C26FFF")
const COLOR_BG_PURPLE = Color("24163D")

const COLOR_TEXT_BLUE = Color("D1FAFF")
const COLOR_BORDER_BLUE = Color("4FE4FF")
const COLOR_BG_BLUE = Color("102339")

const COLOR_TEXT_GOLD = Color("FFE7A8")
const COLOR_BORDER_GOLD = Color("FFBE3B")
const COLOR_BG_GOLD = Color("2A1D0F")

const COLOR_TEXT_WHITE = Color("F4F8FF")
const COLOR_BORDER_WHITE = Color("DCE8FF")
const COLOR_BG_WHITE = Color("1A2236")

const COLOR_DISABLED_TEXT_WHITE = Color("98A4BA")
const COLOR_DISABLED_BORDER_WHITE = Color("5E6A82")
const COLOR_DISABLED_BG_WHITE = Color("1A2233")

const COLOR_TEXT_ORANGE = Color("FFD3A1")
const COLOR_BORDER_ORANGE = Color("FF8A2B")
const COLOR_BG_ORANGE = Color("2B170C")

const COLOR_TAB_BG = Color("162238")
const COLOR_TAB_BORDER = Color("2A3650")

const PRICE_DISABLED_COLOR = Color.DIM_GRAY

func FromColorTextBorderToColor(color_text:String):
	#"WHITE","GOLD","PURPLE","BLUE","DISABLED","TAB_BG","ORANGE"
	match color_text:
		"WHITE":
			return COLOR_BORDER_WHITE
		"GOLD":
			return COLOR_BORDER_GOLD
		"PURPLE":
			return COLOR_BORDER_PURPLE
		"BLUE":
			return COLOR_BORDER_BLUE
		"DISABLED":
			return COLOR_DISABLED_BORDER_WHITE
		"TAB_BG":
			return COLOR_TAB_BORDER
		"ORANGE":
			return COLOR_BORDER_ORANGE
		_:
			return Color.WHITE

func GetBlockColorFromKey(color_key: String) -> Color:
	match color_key.to_lower():
		"brown":
			return Color("#7A4E2C")
		"gray":
			return Color("#7E8799")
		"dark_gray":
			return Color("#4A4F5A")
		"steel":
			return Color("#9AA8BA")
		"orange":
			return Color("#D97A3A")
		"cyan":
			return Color("#4FE4FF")
		"purple":
			return Color("#C26FFF")
		"green":
			return Color("#7BEA49")
		"black":
			return Color("#1C2030")
		"gold":
			return Color("#FFBE3B")
		_:
			return Color("#FFFFFF")

func SkillUpgradeTextToColor(skill_group:String)->String:
	var group = skill_group
	if skill_group.contains(","):
		group = skill_group.split(",")[0]
	match group:
		"power":
			return "ORANGE"
		"speed":
			return "BLUE"
		"economy":
			return "GOLD"
		"offline":
			return "WHITE"
		"special":
			return "PURPLE"
		_:
			print_debug("Unknown color from skill group: ",skill_group)
			return "WHITE"

func GetReadableTextColor(bg: Color) -> Color:
	var luminance = 0.299 * bg.r + 0.587 * bg.g + 0.114 * bg.b
	return Color(0, 0, 0, bg.a) if luminance > 0.5 else Color(1, 1, 1, bg.a)

func GetRelicRankColor(rank: int) -> String:
	var clamped_rank := maxi(1, rank)

	if clamped_rank >= 5:
		return "ORANGE"

	match clamped_rank:
		1, 2:
			return "WHITE"
		3:
			return "PURPLE"
		4:
			return "GOLD"

	return "WHITE"

func GetSkillBranchColor(branch: String) -> String:
	match branch.strip_edges().to_lower():
		"merge":
			return "ORANGE"
		"boss":
			return "GOLD"
		"offline":
			return "WHITE"
		"bot_shop":
			return "PURPLE"
		"tap":
			return "PURPLE"
		"core":
			return "WHITE"
		_:
			return "WHITE"
