extends Control

func _ready() -> void:
	GlobalBtn.AddBtnPress(self)
	GlobalBtn.BtnPress.connect(OnBtnPress)


func OnBtnPress(btn_control:Control):
	if btn_control != self:
		return
	GlobalBtn.AnimateBtnPressed($OfflinePanel)
	GlobalSignals.ShowPopup.emit("OFFLINE_PLANNER",{})
