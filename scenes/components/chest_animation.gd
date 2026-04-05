extends Sprite2D

var _traveling := false
var _travel_time := 0.0
var _travel_duration := 0.45
var _p0 := Vector2.ZERO
var _p1 := Vector2.ZERO
var _p2 := Vector2.ZERO

var cur_fly_node = null

func StartAnimation(chest_icon_type:String) -> void:
	if Global.chest_btn_node:
		cur_fly_node = Global.chest_btn_node
	else:
		cur_fly_node = Global.top_currency_node_coin
	match chest_icon_type:
		"boss":
			texture = preload("res://art/chests/chest_mono_1.tres")
			self_modulate = GlobalColor.COLOR_TEXT_PURPLE
		_:
			print_debug("Unknown chest_icon_type: ",chest_icon_type)
	scale = Vector2.ONE * randf_range(0.85, 1.1)
	modulate.a = 1.0

	var burst_offset := Vector2(
		randf_range(-20.0, 20.0)*2,
		randf_range(-20.0, 8.0)*2
	)

	var burst_target := global_position + burst_offset

	var burst_tween := create_tween()
	burst_tween.parallel().tween_property(self, "global_position", burst_target, 1.0)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	burst_tween.parallel().tween_property(self, "scale", scale * 0.9, 0.20)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	burst_tween.finished.connect(func():
		_start_fly_to_top()
	)


func _start_fly_to_top() -> void:
	if !is_instance_valid(cur_fly_node):
		_traveling = false
		queue_free()
		return
	_p0 = global_position
	_p2 = cur_fly_node.global_position + (cur_fly_node.size / 2)

	var mid := (_p0 + _p2) * 0.5
	mid.y -= randf_range(40.0, 90.0)
	mid.x += randf_range(-20.0, 20.0)

	_p1 = mid
	_travel_time = 0.0
	_traveling = true


func _process(delta: float) -> void:
	if !_traveling:
		return
	if !is_instance_valid(cur_fly_node):
		_traveling = false
		queue_free()
		return

	_travel_time += delta
	var t = clamp(_travel_time / _travel_duration, 0.0, 1.0)

	global_position = _quadratic_bezier(_p0, _p1, _p2, t)

	scale = lerp(scale.x, 0.45, delta * 10.0) * Vector2.ONE
	modulate.a = lerpf(modulate.a, 0.15, delta * 10.0)

	if t >= 1.0:
		_traveling = false
		cur_fly_node.AnimateCurrencyIn()
		queue_free()


func _quadratic_bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	var ab = a.lerp(b, t)
	var bc = b.lerp(c, t)
	return ab.lerp(bc, t)
