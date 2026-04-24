@tool
extends Control
signal OnPress()

@export var buy_btn_title := "NEW UNIT":
	set(value):
		buy_btn_title = value
		if is_node_ready():
			SyncTool()
	get:
		return buy_btn_title

@export_enum("WHITE","GOLD","PURPLE","BLUE","DISABLED","TAB_BG","ORANGE","RED") var panel_color := "PURPLE":
	set(value):
		panel_color = value
		if is_node_ready():
			SyncTool()
	get:
		return panel_color
		
@export var buy_btn_icon : Texture2D = null:
	set(value):
		buy_btn_icon = value
		if is_node_ready():
			SyncTool()
	get:
		return buy_btn_icon

var _disabled_because_of_price = false

@export_enum("SIMPLE_BTN","REWARDED_AD_BTN") var btn_type := "SIMPLE_BTN"

var is_ready = false
func _ready() -> void:
	SyncTool()
	if !Engine.is_editor_hint():
		GlobalBtn.AddBtnPress(self)
		GlobalBtn.AddBtnMouseInOut(self,[$Background])
		GlobalBtn.BtnPress.connect(OnBtnPressed)
		SyncTool()
		if btn_type == "REWARDED_AD_BTN" && !is_ready:
			is_ready = true
			SyncRewardedBtn()
			GlobalAds.rewarded_ready_changed.connect(OnRewardedReady)

func OnRewardedReady(_is_ready):
	SyncRewardedBtn()
	
func SyncTool():
	if !is_node_ready():
		await ready
			
	$Background/HList/Label.text = buy_btn_title
	$Background.panel_color = panel_color
	$Background/HList/icon.texture = buy_btn_icon
	$Background/HList/Label.self_modulate = $Background.GetBorderColor()
	$Background/HList/icon.self_modulate = $Background.GetBorderColor()
	
func ShowOnly(show_btn:Control):
	for x in get_children():
		if x != show_btn:
			x.visible = false
	show_btn.visible = true
	
func SyncRewardedBtn():
	SetDisabled(true)
	if GlobalAds.IsRewardedReady():
		SetDisabled(false)
		
func OnBtnPressed(btn_node:Control):
	if btn_node != self:
		return
	if _disabled_because_of_price:
		return
	GlobalBtn.AnimateBtnPressed($Background)
	match btn_type:
		"REWARDED_AD_BTN":
			GlobalBtn.AnimateBtnPressed($Background)
			GlobalAds.ShowRewarded()
			if !GlobalAds.IsRewardedReady():
				return
			await GlobalAds.rewarded_reward_earned
			OnPress.emit()
		_:
			OnPress.emit()

func SetDisabled(_is_disabled:bool):
	if OS.get_name() == "Linux":
		if _is_disabled:
			$Background/HList/Label.text = buy_btn_title + " - (disabled)"
			return
	if _is_disabled:
		_disabled_because_of_price = true
		modulate = GlobalColor.PRICE_DISABLED_COLOR
	else:
		modulate = Color.WHITE
		_disabled_because_of_price = false
