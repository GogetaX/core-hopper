extends Control


var _is_toggled := false

const COLOR_BG_ENABLED = Color("4fe4ff")
const COLOR_BG_DISABLED = Color("0f272c")

const COLOR_CURSOR_ENABLED = Color("dffaff")
const COLOR_CURSOR_DISABLED = Color("83979c")


func _ready() -> void:
	GlobalBtn.AddBtnPress(self)
	GlobalBtn.BtnPress.connect(OnTogglePressed)
	AnimateToggleInOut()
	
func SetEnabled(is_enabled:bool):
	_is_toggled = is_enabled
	AnimateToggleInOut()
	
func OnTogglePressed(control_node:Control):
	if control_node != self:
		return
	_is_toggled = !_is_toggled
	AnimateToggleInOut()

func AnimateToggleInOut():
	if _is_toggled:
		var t = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
		t.tween_property($CURSOR,"position:x",size.x-60,0.2)
		var bg_style : StyleBoxFlat = $TOGGLE_BG.get_theme_stylebox("panel")
		t.parallel().tween_property(bg_style,"bg_color",COLOR_BG_ENABLED,0.2)
		t.parallel().tween_property(bg_style,"shadow_size",10,0.2)
		var cursor_style : StyleBoxFlat = $CURSOR.get_theme_stylebox("panel")
		t.parallel().tween_property(cursor_style,"bg_color",COLOR_CURSOR_ENABLED,0.2)

	else:
		var t = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
		t.tween_property($CURSOR,"position:x",20,0.2)
		var bg_style : StyleBoxFlat = $TOGGLE_BG.get_theme_stylebox("panel")
		t.parallel().tween_property(bg_style,"bg_color",COLOR_BG_DISABLED,0.2)
		t.parallel().tween_property(bg_style,"shadow_size",0,0.2)
		var cursor_style : StyleBoxFlat = $CURSOR.get_theme_stylebox("panel")
		t.parallel().tween_property(cursor_style,"bg_color",COLOR_CURSOR_DISABLED,0.2)
