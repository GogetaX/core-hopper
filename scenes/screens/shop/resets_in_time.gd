extends Node

func _ready() -> void:
	get_parent().ready.connect(OnParentReady)
	
func OnParentReady():
	_on_timer_timeout()
	
func _on_timer_timeout() -> void:
	if get_parent().is_node_ready():
		get_parent().text = "Resets in "+GlobalTimedBonus.GetDailyTaskResetCountdownText()
