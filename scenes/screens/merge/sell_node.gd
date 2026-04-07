extends Control

class_name MergeSellClass

var is_mouse_in = false

var show_state = "HIDDEN"

func _ready() -> void:
	visible = false
	modulate.a = 0.0

func _process(_delta: float) -> void:
	if show_state == "HIDDEN" && !Global.cur_drag_data.is_empty() && $wait_before_show.is_stopped():
		$wait_before_show.start()
	if show_state == "SHOWN" && Global.cur_drag_data.is_empty():
		show_state = "HIDDEN"
		var t = create_tween()
		visible = true
		t.tween_property(self,"modulate:a",0.0,0.1)
		t.finished.connect(func():visible = false)
		
	if show_state == "SHOWN" && !Global.cur_drag_data.is_empty() && get_global_rect().has_point(get_global_mouse_position()):
		if Global.mouse_at_sell_node == null:
			SetMouseIn()
			Global.mouse_at_sell_node = self
		Global.cur_drag_data = {"at_sell_node":self}
	else:
		if Global.mouse_at_sell_node == self:
			SetMouseOut()
			Global.mouse_at_sell_node = null
	
func SetMouseIn():
	is_mouse_in = true
	var t = create_tween()
	t.tween_property($SmartPanel/VList/TextureRect,"self_modulate",Color.DARK_RED,0.1)

func SetMouseOut():
	is_mouse_in = false
	var t = create_tween()
	t.tween_property($SmartPanel/VList/TextureRect,"self_modulate",GlobalColor.COLOR_BORDER_ORANGE,0.1)


func _on_wait_before_show_timeout() -> void:
	show_state = "SHOWN"
	visible = true
	var t = create_tween()
	t.tween_property(self,"modulate:a",1.0,0.1)
	
