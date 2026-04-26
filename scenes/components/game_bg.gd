extends Control

func _ready() -> void:
	GlobalSignals.OnTabBtnpressed.connect(OnBottomTabPressed)
	$BG_IN.texture = null
	$BG_OUT.texture = null
	ShowBG("DIG")
	
func OnBottomTabPressed(btn_node:ButtonTabClass):
	ShowBG(btn_node.btn_name)
	
func ShowBG(bg_name:String):
	match bg_name:
		"DIG":
			AnimateTexture("res://art/background/dig_bg.png")
		_:
			AnimateTexture("res://art/background/merge_screen.png")

func AnimateTexture(texture_file:String):
	var tex = load(texture_file)
	$BG_OUT.self_modulate.a = 1.0
	$BG_OUT.texture = $BG_IN.texture
	$BG_IN.texture = tex
	$BG_IN.self_modulate.a = 0.0
	var t = create_tween()
	t.tween_property($BG_OUT,"self_modulate:a",0.0,0.2)
	t.parallel().tween_property($BG_IN,"self_modulate:a",1.0,0.2)
	
