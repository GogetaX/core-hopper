extends Node

const CANCEL_DISTANCE := 5.0
var start_pos := Vector2.ZERO
var canceled := false
signal BtnPress(btn_node:Control)

func AddBtnPress(btn_node:Control):
	if btn_node.gui_input.is_connected(_gui_input.bind(btn_node)):
		print_debug("ALREADY CONNECTED?")
	btn_node.gui_input.connect(_gui_input.bind(btn_node))

func AddBtnMouseInOut(btn_node:Control,anim_node_list:Array):
	btn_node.mouse_entered.connect(_OnMouseEntered.bind(anim_node_list))
	btn_node.mouse_exited.connect(_OnMouseExited.bind(anim_node_list))

func _OnMouseEntered(anim_node_list:Array):
	for x in anim_node_list:
		if x.visible:
			var t = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
			t.tween_property(x,"modulate",Color.GRAY,0.05)
	
func _OnMouseExited(anim_node_list:Array):
	for x in anim_node_list:
		if x.visible:
			var t = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
			t.tween_property(x,"modulate",Color.WHITE,0.05)
	
func _gui_input(event,btn_node:Control):
	if event is InputEventMouseButton and event.pressed && event.button_index == 1:
		start_pos = event.position
		canceled = false

	if event is InputEventMouseMotion:
		if event.position.distance_to(start_pos) > CANCEL_DISTANCE:
			canceled = true

	if event is InputEventMouseButton and !event.pressed:
		if canceled:
			return  # Don't trigger click
		BtnPress.emit(btn_node)

func AnimateBtnPressed(anim_panel:Control):
	if !anim_panel.visible:
		return
	var t = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	t.tween_property(anim_panel,"scale",Vector2(0.9,0.9),0.05)
	t.tween_property(anim_panel,"scale",Vector2(1.0,1.0),0.05)
