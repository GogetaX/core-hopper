extends Control
class_name NotifItemClass

var to_y_size = 0.0

func InitTextNotif(text:String,color_str:String)->void:
	_RemoveAllPanels()
	$SmartPanel.panel_color = color_str
	$TextItem/ProgressHashTag.hash_tag_color = color_str
	$TextItem.visible = true
	modulate.a = 0.0
	custom_minimum_size.y = 0
	$notif_timer.start()
	$TextItem/ProgressHashTag.text = text

func _RemoveAllPanels():
	for x in get_children():
		if x is VBoxContainer:
			x.visible = false
			
			
func _process(delta: float) -> void:
	if custom_minimum_size.y != to_y_size:
		custom_minimum_size.y = lerpf(custom_minimum_size.y,to_y_size,delta * 20.0)

func _on_text_item_resized() -> void:
	var max_y = $TextItem.get_minimum_size().y
	to_y_size = max_y + 20
	size.y = 0.0
	var t = create_tween()
	t.tween_property(self,"modulate:a",1.0,0.2)


func _on_notif_timer_timeout() -> void:
	var t = create_tween()
	t.tween_property(self,"modulate:a",0.0,0.2)
	t.parallel().tween_property(self,"custom_minimum_size:y",0.0,0.2)
	t.parallel().tween_property(self,"size:y",0.0,0.2)
	t.finished.connect(func():queue_free())
	
