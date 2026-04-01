extends Panel
class_name DigBotClass

const BUY_STATE_DISABLED = Color("3c3c3c")
const BUY_STATE_ENABLED = Color.WHITE

@export var cur_lane := 1

var cur_lane_data = {}
var _has_bot_to_drag := false

var is_mouse_inside = false
var drag_state = "IDLE"
var last_mouse_pos = Vector2.ZERO

func _ready() -> void:
	$State_DigBot/IsDragIn.visible = false
	GlobalSignals.DataSaved.connect(SyncLaneData)
	GlobalBtn.AddBtnPress($State_BuyBot)
	GlobalBtn.AddBtnPress($State_DigBot)
	GlobalBtn.BtnPress.connect(OnBuyStateBtn)
	SyncLaneData()
	
func _process(_delta: float) -> void:
	is_mouse_inside = get_global_rect().has_point(get_global_mouse_position())
	#Handle start-drag with mouse
	if _has_bot_to_drag:
		
		if is_mouse_inside && Input.is_action_just_pressed("ui_tap") && drag_state == "IDLE":
			last_mouse_pos = get_global_mouse_position()
			drag_state = "WAITING_TO_MAX_DISTANCE"
		if Input.is_action_pressed("ui_tap") && drag_state == "WAITING_TO_MAX_DISTANCE" && last_mouse_pos.distance_to(get_global_mouse_position()) > Global.ACTIVE_DRAG_AFTER_DISTANCE:
			drag_state = "IS_DRAGGING"
			GlobalSignals.StartDragBotItem.emit(self)
	if drag_state != "IDLE" && !Input.is_action_pressed("ui_tap"):
		drag_state = "IDLE"
	
	#Handle already dragging? dragged into this node
	var drag_in_visible = false
	var drag_default_color = "BLUE"
	if Global.cur_dragging_node:
		if Input.is_action_pressed("ui_tap"):
			#if dragging on self
			if Global.cur_dragging_node.cur_dragging_bot_node == self:
				if is_mouse_inside:
					if cur_lane_data.auto_dig_unlocked:
						Global.cur_drag_data = {"at_self_dig_bot":true}
						drag_in_visible = true
					else:
						drag_default_color = "ORANGE"
						drag_in_visible = true
			if Global.cur_dragging_node.cur_dragging_bot_node != self:
				if is_mouse_inside:
					if cur_lane_data.auto_dig_unlocked:
						drag_in_visible = true
						Global.cur_drag_data = {"at_other_dig_bot":self}
					else:
						drag_in_visible = true
						drag_default_color = "ORANGE"
	if $State_DigBot/IsDragIn.visible != drag_in_visible:
		$State_DigBot/IsDragIn.visible = drag_in_visible
	if $State_DigBot/IsDragIn.panel_color != drag_default_color:
		$State_DigBot/IsDragIn.panel_color = drag_default_color

func GetCurState():
	cur_lane_data = GlobalSave.GetLaneData(cur_lane)
	
	if !cur_lane_data.is_empty():
		if cur_lane_data.auto_dig_unlocked:
			return "State_DigBot"

	match cur_lane:
		1:
			return "State_BuySlot"
		2:
			if GlobalSave.save_data.progress.global_depth < 150:
				return "State_Reach150m"
			else:
				GlobalSave.ActivateLane(cur_lane)
				GlobalSave.SyncSave()
				return "State_DigBot"
	return "State_DigBot"
	
func HideAllStates():
	for x in get_children():
		x.visible = false
		
func SyncLaneData():
	var cur_state = GetCurState()
	HideAllStates()
	match cur_state:
		"State_DigBot":
			State_DigBot()
		"State_BuySlot":
			State_BuyBot()
		"State_Reach150m":
			return State_Reach150M()
		_:
			print_debug("Unknown state: ",cur_state)
		

func State_Reach150M():
	$State_Reach150m.visible = true
	
func OnBuyStateBtn(control:Control):
	if control  == $State_BuyBot:
		var currency = GlobalSave.GetCurrency("coins")
		if currency>=100:
			GlobalBtn.AnimateBtnPressed($State_BuyBot)
			GlobalSave.RemoveCurrency("coins",100)
			GlobalSave.ActivateLane(cur_lane)
			GlobalSave.SyncSave()
	elif control == $State_DigBot:
		if cur_lane_data.is_empty():
			return
		if cur_lane_data.auto_dig_unlocked && cur_lane_data.bot_uid == -1:
			GlobalBtn.AnimateBtnPressed($State_DigBot)
			GlobalSignals.OpenTabFromStr.emit("MERGE")
		
func State_BuyBot():
	$State_BuyBot.visible = true
	#Check if i have 100 money
	var currency = GlobalSave.GetCurrency("coins")
	if currency<100:
		$State_BuyBot.modulate = BUY_STATE_DISABLED
	else:
		$State_BuyBot.modulate = BUY_STATE_ENABLED
	
func State_DigBot():
	$State_DigBot.visible = true
	$State_DigBot/VList/bot_icon.visible = false
	$State_DigBot/VList/locked_icon.visible = false
	$State_DigBot/cur_lvl.visible = false
	$State_DigBot/VList/dps_label.visible = false
	_has_bot_to_drag = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if !cur_lane_data.auto_dig_unlocked:
		$State_DigBot/VList/locked_icon.visible = true
		$State_DigBot/VList/locked_icon.texture = preload("res://art/icons/20_px/lock_icon.png")
		$State_DigBot/VList/locked_icon.self_modulate.a = 0.3
	elif cur_lane_data.bot_uid == -1:
		$State_DigBot/VList/locked_icon.texture = preload("res://art/icons/20_px/plus_icon.png")
		$State_DigBot/VList/locked_icon.visible = true
	else:
		mouse_filter = Control.MOUSE_FILTER_STOP
		_has_bot_to_drag = true
		$State_DigBot/VList/bot_icon.visible = true
		$State_DigBot/VList/dps_label.visible = true
		var bot_data = GlobalSave.GetBotDataFromUID(cur_lane_data.bot_uid)
		$State_DigBot/VList/bot_icon.SetImageFromBotNum(int(bot_data.level))
		$State_DigBot/VList/dps_label.text = str(GlobalStats.GetBotFinalDPSWithGobal(bot_data.level)).pad_decimals(0) + " DPS"
		$State_DigBot/cur_lvl.visible = true
		$State_DigBot/cur_lvl.text = "LV "+str(bot_data.level).pad_decimals(0)
