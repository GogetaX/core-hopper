extends Control

func _ready() -> void:
	GlobalBtn.AddBtnPress(self)
	GlobalBtn.BtnPress.connect(OnLockedBtnPress)
	
func OnLockedBtnPress(btn_control:Control):
	if btn_control != self:
		return
	GlobalSignals.AddNotification.emit({"type":"TEXT","description":"LOCKED RELIC\nUnlock: Skill tree and game progress","color":"WHITE"})
