extends TextureRect

func InitIconFromEffect(special_type:String)->void:
	match special_type:
		"regen":
			texture = load("res://art/icons/20_px/plus_icon.png")
			self_modulate = Color.GREEN
		"tap_resist":
			texture = load("res://art/particles/tap_resist.png")
			self_modulate = Color.DARK_RED
		"armor":
			texture = load("res://art/particles/shield_icon.png")
			self_modulate = GlobalColor.COLOR_BORDER_BLUE
		"timer_enrage":
			texture = load("res://art/icons/time_cap.png")
			self_modulate = GlobalColor.COLOR_BORDER_BLUE
		"shield_cycle":
			texture = load("res://art/particles/shield_circle.png")
			self_modulate = GlobalColor.COLOR_BORDER_ORANGE
		_:
			texture = null
			print_debug("Unknown special_type: ",special_type)
