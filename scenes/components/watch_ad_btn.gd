@tool
extends Control

signal OnAdGained()

@export var title := "CLAIM X2 REWARDS":
	set(value):
		title = value
		if is_node_ready():
			_ready()
	get:
		return title
@export var subtitle := "WATCH AD":
	set(value):
		subtitle = value
		if is_node_ready():
			_ready()
	get:
		return subtitle
		
var _disabled_because_of_price = false

func _ready() -> void:
	$SmartPanel/HList/VList/title_label.text = title
	$SmartPanel/HList/VList/subtitle_label.text = subtitle
	if !Engine.is_editor_hint():
		GlobalBtn.AddBtnPress(self)
		GlobalBtn.BtnPress.connect(OnBtnPressed)
		GlobalBtn.AddBtnMouseInOut(self,[$SmartPanel])
		GlobalAds.rewarded_ready_changed.connect(OnRewardedIsReady)
		SyncRewardedReady()

func OnRewardedIsReady(_is_ready):
	SyncRewardedReady()
	
func SetDisabled(_is_disabled:bool):
	if _is_disabled:
		_disabled_because_of_price = true
		modulate = GlobalColor.PRICE_DISABLED_COLOR
	else:
		modulate = Color.WHITE
		_disabled_because_of_price = false
		
func SyncRewardedReady():
	SetDisabled(true)
	if GlobalAds.IsRewardedReady():
		SetDisabled(false)
	
func OnBtnPressed(btn_node:Control):
	if btn_node != self:
		return
	if !GlobalAds.IsRewardedReady():
		return
	GlobalBtn.AnimateBtnPressed($SmartPanel)
	GlobalAds.ShowRewarded()
	await GlobalAds.rewarded_reward_earned
	OnAdGained.emit()
