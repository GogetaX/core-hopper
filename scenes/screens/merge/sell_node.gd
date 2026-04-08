extends Control

class_name MergeSellClass

var is_mouse_in = false

var show_state = "HIDDEN"

func _ready() -> void:
	$SellPrice.modulate.a = 0.0
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
			if Global.cur_dragging_node.cur_dragging_merge_node:
				var bot_sell_value = GlobalStats.GetBotSellValue(Global.cur_dragging_node.cur_dragging_merge_node.cur_bot_data.level)
				$SellPrice/HBoxContainer/sell_value.text = Global.CurrencyToString(bot_sell_value)
			elif Global.cur_dragging_node.cur_dragging_bot_node:
				var bot_lane_data = Global.cur_dragging_node.cur_dragging_bot_node.cur_lane_data
				var bot_data = GlobalSave.GetBotDataFromUID(bot_lane_data.bot_uid)
				var bot_sell_value = GlobalStats.GetBotSellValue(bot_data.level)
				$SellPrice/HBoxContainer/sell_value.text = Global.CurrencyToString(bot_sell_value)
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
	t.parallel().tween_property($SellPrice,"position:y",-70,0.1)
	t.parallel().tween_property($SellPrice,"modulate:a",1.0,0.1)
	
func SetMouseOut():
	is_mouse_in = false
	var t = create_tween()
	t.tween_property($SmartPanel/VList/TextureRect,"self_modulate",GlobalColor.COLOR_BORDER_ORANGE,0.1)
	t.parallel().tween_property($SellPrice,"position:y",0,0.1)
	t.parallel().tween_property($SellPrice,"modulate:a",0.0,0.1)
	

func _on_wait_before_show_timeout() -> void:
	show_state = "SHOWN"
	visible = true
	var t = create_tween()
	t.tween_property(self,"modulate:a",1.0,0.1)
	
