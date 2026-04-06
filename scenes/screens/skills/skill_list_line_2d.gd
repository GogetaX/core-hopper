extends Line2D
class_name SkillLineClass


func InitLine(from_glob_pos:Vector2,to_glob_pos:Vector2,from_color_str:String,to_color_str:String):
	points[0] = from_glob_pos
	points[1] = to_glob_pos
	gradient.set_color(0,FromColorTextBorderToColor(from_color_str))
	gradient.set_color(1,FromColorTextBorderToColor(to_color_str))
	
			
func FromColorTextBorderToColor(color_text:String):
	#"WHITE","GOLD","PURPLE","BLUE","DISABLED","TAB_BG","ORANGE"
	match color_text:
		"WHITE":
			return GlobalColor.COLOR_BORDER_WHITE
		"GOLD":
			return GlobalColor.COLOR_BORDER_GOLD
		"PURPLE":
			return GlobalColor.COLOR_BORDER_PURPLE
		"BLUE":
			return GlobalColor.COLOR_BORDER_BLUE
		"DISABLED":
			return GlobalColor.COLOR_DISABLED_BORDER_WHITE
		"TAB_BG":
			return GlobalColor.COLOR_TAB_BORDER
		"ORANGE":
			return GlobalColor.COLOR_BORDER_ORANGE
		_:
			return Color.WHITE
