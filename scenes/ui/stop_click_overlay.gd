extends Control

func _ready() -> void:
	GlobalSignals.StopScreenClick.connect(OnStopScreenClick)
	
func OnStopScreenClick(is_stopped:bool):
	visible = is_stopped
