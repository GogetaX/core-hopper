extends GPUParticles2D

func _ready() -> void:
	one_shot = true
	$free_timer.start(lifetime)


func _on_free_timer_timeout() -> void:
	queue_free()
