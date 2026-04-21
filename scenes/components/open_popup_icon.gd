@tool
extends Control

@export_enum("WHITE","GOLD","PURPLE","BLUE","DISABLED","TAB_BG","ORANGE","RED") var panel_color := "PURPLE":
	set(value):
		panel_color = value
		if is_node_ready():
			_ready()
	get:
		return panel_color
		

func _ready() -> void:
	SyncColor()
	
func SyncColor():
	match panel_color:
		"WHITE":
			$arrow_rect.self_modulate = GlobalColor.COLOR_BORDER_WHITE
			$border_rect.self_modulate = GlobalColor.COLOR_TEXT_WHITE
		"GOLD":
			$arrow_rect.self_modulate = GlobalColor.COLOR_BORDER_GOLD
			$border_rect.self_modulate = GlobalColor.COLOR_TEXT_GOLD
		"PURPLE":
			$arrow_rect.self_modulate = GlobalColor.COLOR_BORDER_PURPLE
			$border_rect.self_modulate = GlobalColor.COLOR_TEXT_PURPLE
		"BLUE":
			$arrow_rect.self_modulate = GlobalColor.COLOR_BORDER_BLUE
			$border_rect.self_modulate = GlobalColor.COLOR_TEXT_BLUE
		"ORANGE":
			$arrow_rect.self_modulate = GlobalColor.COLOR_BORDER_ORANGE
			$border_rect.self_modulate = GlobalColor.COLOR_TEXT_ORANGE
		"RED":
			$arrow_rect.self_modulate = GlobalColor.COLOR_BORDER_RED
			$border_rect.self_modulate = GlobalColor.COLOR_TEXT_RED
		_:
			print_debug("Unknown Color: ",panel_color)
