@tool
extends Line2D

@export_enum("WHITE","GOLD","PURPLE","BLUE","DISABLED","TAB_BG","ORANGE") var start_color := "PURPLE":
	set(value):
		start_color = value
		if is_node_ready():
			_ready()
	get:
		return start_color

@export_enum("WHITE","GOLD","PURPLE","BLUE","DISABLED","TAB_BG","ORANGE") var end_color := "PURPLE":
	set(value):
		end_color = value
		if is_node_ready():
			_ready()
	get:
		return end_color

func _ready() -> void:
	if gradient.get_point_count() == 2:
		gradient.set_color(0,FromColorTextBorderToColor(start_color))
		gradient.set_color(1,FromColorTextBorderToColor(end_color))
	else:
		for x in gradient.get_point_count():
			gradient.set_color(x,Color.WHITE)
			
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
