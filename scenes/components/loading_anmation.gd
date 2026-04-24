extends Control

func _process(delta: float) -> void:
	$Control/GPUParticles2D.rotation += delta * 5
