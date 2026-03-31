@tool
extends Label

const COLOR_SYNCED = Color("51fc5a")
const COLOR_NOT_CYNCED = Color("fc5158")

@export var set_synced := false:
	set(value):
		set_synced = value
		if is_node_ready():
			_ready()
	get:
		return set_synced

func _ready() -> void:
	if set_synced:
		$StatusIcon.self_modulate = COLOR_SYNCED
	else:
		$StatusIcon.self_modulate = COLOR_NOT_CYNCED
