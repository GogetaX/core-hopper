extends Camera2D

const CAMERA_OFFSET = 250
const LIMIT_OFFSET = 800

@export var min_zoom: float = 0.55
@export var max_zoom: float = 2.20
@export var drag_sensitivity: float = 2.0
@export var wheel_zoom_step: float = 0.12
@export var zoom_pan_compensation: float = 1.0
# 0.0 = no zoom compensation
# 1.0 = full zoom compensation
# 0.5 = softer compensation

var _touches: Dictionary = {}
var _last_pinch_distance: float = 0.0

func _ready() -> void:
	GlobalSignals.ResetSkillCamera.connect(OnResetSkillCamera)
	GlobalSignals.CenterCameraCurSelectedSkill.connect(OnCurSelectedSkill)
	GlobalSignals.SkillsFinishedCreating.connect(OnSetCameraLimits)
	OnResetSkillCamera()
	
	

func OnSetCameraLimits():
	await get_tree().process_frame
	#Setting camera limits
	var limits : Rect2i = get_parent().GetSkillLimitRect()
	limit_left = limits.position.x-LIMIT_OFFSET
	limit_right = limits.position.y+LIMIT_OFFSET
	limit_top = limits.size.x-LIMIT_OFFSET
	limit_bottom = limits.size.y+LIMIT_OFFSET
	
func OnCurSelectedSkill():
	var cur_skill = get_parent().GetCurSelectedSkill() as WorldSkillClass
	if cur_skill:
		global_position = cur_skill.global_position
		global_position.y += CAMERA_OFFSET
func OnResetSkillCamera():
	global_position = Vector2(0,CAMERA_OFFSET)
	zoom = Vector2(1.0,1.0)
	

func _unhandled_input(event: InputEvent) -> void:
	# --- Touch press/release ---
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)

		if _touches.size() == 2:
			_last_pinch_distance = _get_pinch_distance()
		else:
			_last_pinch_distance = 0.0

	# --- Touch drag ---
	elif event is InputEventScreenDrag:
		_touches[event.index] = event.position

		# One finger = pan
		if _touches.size() == 1:
			_pan_by_screen_delta(event.screen_relative)

		# Two fingers = pinch zoom
		elif _touches.size() >= 2:
			var new_distance := _get_pinch_distance()
			if _last_pinch_distance > 0.0 and new_distance > 0.0:
				var factor := _last_pinch_distance / new_distance
				var center := _get_pinch_center()
				_zoom_at_screen_point(zoom.x * factor, center)
			_last_pinch_distance = new_distance

	# --- Mouse wheel zoom for editor / desktop testing ---
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at_screen_point(zoom.x * (1.0 - wheel_zoom_step), event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at_screen_point(zoom.x * (1.0 + wheel_zoom_step), event.position)


func _pan_by_screen_delta(screen_delta: Vector2) -> void:
	global_position -= (screen_delta / zoom.x) * drag_sensitivity

func _zoom_at_screen_point(new_zoom: float, screen_point: Vector2) -> void:
	new_zoom = clamp(new_zoom, min_zoom, max_zoom)

	# World point under the fingers BEFORE zoom
	var world_before := _screen_to_world(screen_point)

	zoom = Vector2.ONE * new_zoom
	force_update_scroll()

	# World point under the fingers AFTER zoom
	var world_after := _screen_to_world(screen_point)

	# Shift camera so the same world point stays under the pinch center
	global_position += world_before - world_after


func _screen_to_world(screen_point: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_point


func _get_pinch_distance() -> float:
	if _touches.size() < 2:
		return 0.0

	var points := _touches.values()
	return (points[0] as Vector2).distance_to(points[1] as Vector2)


func _get_pinch_center() -> Vector2:
	if _touches.size() < 2:
		return Vector2.ZERO

	var points := _touches.values()
	return ((points[0] as Vector2) + (points[1] as Vector2)) * 0.5
