@tool
extends Control

@export_enum("BORDER_ONLY","INSIDE_ONLY","BORDER_AND_INSIDE") var panel_type = "BORDER_AND_INSIDE":
	set(value):
		panel_type = value
		if is_node_ready():
			_ready()
	get:
		return panel_type

@export_enum("WHITE","GOLD","PURPLE","BLUE","DISABLED","TAB_BG","ORANGE","RED") var panel_color := "PURPLE":
	set(value):
		panel_color = value
		if is_node_ready():
			_ready()
	get:
		return panel_color
		
@export var set_border_as_bg := false:
	set(value):
		set_border_as_bg = value
		if is_node_ready():
			_ready()
	get:
		return set_border_as_bg

@export var darken_bg := false:
	set(value):
		darken_bg = value
		if is_node_ready():
			_ready()
	get:
		return darken_bg

var animation_tween : Tween = null
func _ready():
	#Init borders
	match panel_type:
		"BORDER_ONLY":
			$BGOnly.visible = false
			$BorderOnly.visible = true
		"INSIDE_ONLY":
			$BGOnly.visible = true
			$BorderOnly.visible = false
		"BORDER_AND_INSIDE":
			$BorderOnly.visible = true
			$BGOnly.visible = true
	#Init Colors
	match panel_color:
		"WHITE":
			$BGOnly.self_modulate = GlobalColor.COLOR_BG_WHITE
			$BorderOnly.self_modulate = GlobalColor.COLOR_BORDER_WHITE
			if set_border_as_bg:
				$BGOnly.self_modulate = GlobalColor.COLOR_TEXT_WHITE
				$BorderOnly.self_modulate = GlobalColor.COLOR_BG_WHITE
		"BLUE":
			$BGOnly.self_modulate = GlobalColor.COLOR_BG_BLUE
			$BorderOnly.self_modulate = GlobalColor.COLOR_BORDER_BLUE
			if set_border_as_bg:
				$BGOnly.self_modulate = GlobalColor.COLOR_TEXT_BLUE
				$BorderOnly.self_modulate = GlobalColor.COLOR_BG_BLUE
			
		"PURPLE":
			$BGOnly.self_modulate = GlobalColor.COLOR_BG_PURPLE
			$BorderOnly.self_modulate = GlobalColor.COLOR_BORDER_PURPLE
			if set_border_as_bg:
				$BGOnly.self_modulate = GlobalColor.COLOR_TEXT_PURPLE
				$BorderOnly.self_modulate = GlobalColor.COLOR_BG_PURPLE
			
		"GOLD":
			$BGOnly.self_modulate = GlobalColor.COLOR_BG_GOLD
			$BorderOnly.self_modulate = GlobalColor.COLOR_BORDER_GOLD
			if set_border_as_bg:
				$BGOnly.self_modulate = GlobalColor.COLOR_TEXT_GOLD
				$BorderOnly.self_modulate = GlobalColor.COLOR_BG_GOLD
		"DISABLED":
			$BGOnly.self_modulate = GlobalColor.COLOR_DISABLED_BG_WHITE
			$BorderOnly.self_modulate = GlobalColor.COLOR_DISABLED_BORDER_WHITE
			if set_border_as_bg:
				$BGOnly.self_modulate = GlobalColor.COLOR_DISABLED_TEXT_WHITE
				$BorderOnly.self_modulate = GlobalColor.COLOR_DISABLED_BG_WHITE
		"TAB_BG":
			$BGOnly.self_modulate = GlobalColor.COLOR_TAB_BG
			$BorderOnly.self_modulate = GlobalColor.COLOR_TAB_BORDER
			
		"ORANGE":
			$BGOnly.self_modulate = GlobalColor.COLOR_BG_ORANGE
			$BorderOnly.self_modulate = GlobalColor.COLOR_BORDER_ORANGE
			if set_border_as_bg:
				$BGOnly.self_modulate = GlobalColor.COLOR_TEXT_ORANGE
				$BorderOnly.self_modulate = GlobalColor.COLOR_BG_ORANGE
		"RED":
			$BGOnly.self_modulate = GlobalColor.COLOR_BG_RED
			$BorderOnly.self_modulate = GlobalColor.COLOR_BORDER_RED
			if set_border_as_bg:
				$BGOnly.self_modulate = GlobalColor.COLOR_TEXT_RED
				$BorderOnly.self_modulate = GlobalColor.COLOR_BG_RED
				
	if darken_bg:
		#var relic_bg_color = Color(0.1,0.1,0.1,0.5)
		$BGOnly.self_modulate = GlobalColor.COLOR_DISABLED_BG_WHITE / 2.0

func GetTextColor():
	match panel_color:
		"WHITE":
			if set_border_as_bg:
				return GlobalColor.COLOR_BORDER_WHITE
			else:
				return GlobalColor.COLOR_TEXT_WHITE
			
		"BLUE":
			if set_border_as_bg:
				return GlobalColor.COLOR_BORDER_BLUE
			else:
				return GlobalColor.COLOR_TEXT_BLUE
			
		"PURPLE":
			if set_border_as_bg:
				return GlobalColor.COLOR_BORDER_PURPLE
			else:
				return GlobalColor.COLOR_TEXT_PURPLE
			
		"GOLD":
			if set_border_as_bg:
				return GlobalColor.COLOR_BORDER_GOLD
			else:
				return GlobalColor.COLOR_TEXT_GOLD
		"ORANGE":
			if set_border_as_bg:
				return GlobalColor.COLOR_BORDER_ORANGE
			else:
				return GlobalColor.COLOR_TEXT_ORANGE
		"DISABLED":
			if set_border_as_bg:
				return GlobalColor.COLOR_BORDER_WHITE
			else:
				return GlobalColor.COLOR_DISABLED_TEXT_WHITE
		"RED":
			if set_border_as_bg:
				return GlobalColor.COLOR_BORDER_RED
			else:
				return GlobalColor.COLOR_TEXT_RED
	print_debug("Unknown panel color: ",panel_color)
	return Color.WHITE
	
func GetBorderColor():
	return $BorderOnly.self_modulate

func GetBGColor():
	return $BGOnly.self_modulate
	
func AnimateShadow(start_animation:bool):
	if start_animation:
		if animation_tween:
			animation_tween.kill()
		animation_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK).set_loops(0)
		var bg_style : StyleBoxFlat = $BorderOnly.get_theme_stylebox("panel")
		#animation_tween.tween_property(bg_style,"shadow_color:a",0.6,1.0)
		animation_tween.tween_property(bg_style,"shadow_size",10,1.0)
		#animation_tween.tween_property(bg_style,"shadow_color:a",0.2,1.0)
		animation_tween.tween_property(bg_style,"shadow_size",2,1.0)
	if !start_animation:
		if animation_tween:
			if animation_tween.is_running():
				animation_tween.kill()
			animation_tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BACK)
			var bg_style : StyleBoxFlat = $BorderOnly.get_theme_stylebox("panel")
			animation_tween.tween_property(bg_style,"shadow_size",2,1.0)
