extends Control

func _ready() -> void:
	SyncParticleSizeAndPos()
	
func SyncParticleSizeAndPos():
	$GPUParticles2D.position = size / 2.0
	$GPUParticles2D.process_material.emission_box_extents = Vector3(size.x/2.2,size.y/2.2,1.0)
	


func _on_resized() -> void:
	SyncParticleSizeAndPos()
