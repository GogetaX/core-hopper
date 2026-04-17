extends CanvasLayer

var start_pos = Vector2.ZERO
var vib_timer = 0.0
var vib_amp = 1.0
var dup_glich_shader = null

func _ready() -> void:
	GlobalSignals.StartResetAnim.connect(StartAnim)
	start_pos = $TextureRect.position
	vib_timer = $vibr_timer.wait_time
	dup_glich_shader = $TextureRect.material
	$TextureRect.material = null
	visible = false


		
func StartAnim():
	vib_amp = 1.0
	vib_timer = 0.0
	visible = true
	$TextureRect.visible = true
	$TextureRect.scale = Vector2(1.0,1.0)
	$AnimationPlayer.play("step_1")
	
	
func StartVibr():
	$TextureRect.material = dup_glich_shader 
	$vibr_timer.start(1.0)
	
func _on_vibr_timer_timeout() -> void:
	
	var t = create_tween()
	var rand_pos = Vector2(randf_range(-1.0,1.0),randf_range(-1.0,1.0))*vib_amp
	t.tween_property($TextureRect,"position",start_pos + rand_pos,0.1)
	t.tween_property($TextureRect,"position",start_pos - rand_pos,0.1)
	t.tween_property($TextureRect,"position",start_pos,0.1)
	vib_timer -= 0.1
	
	vib_amp += 1
	if vib_amp > 5:
		$AnimationPlayer.play("step_2")
	else:
		$vibr_timer.start(vib_timer)
	
func ResetShaderAndAll():
	$TextureRect.material = null
	$TextureRect.visible = false
	GlobalSignals.OnResetAnimStep.emit("WHITE_BG")
	
func HideAndContinuePlaying():
	visible = false
