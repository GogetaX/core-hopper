extends Panel
class_name MergeItemClass



var _is_unlocked = false

var cur_bot_id = -1

var cur_bot_data = {}

var _has_bot_to_drag = false
var drag_state = "IDLE"
var last_mouse_pos = Vector2.ZERO
var is_mouse_inside = false

func _ready() -> void:
	GlobalSignals.DataSaved.connect(SyncBotData)
	get_parent().ready.connect(OnParentReady)
	$BotImage.visible = false
	$IsDragIn.visible = false
	$BotLevel.visible = false
	$BotDPS.visible = false
	$rank_color.visible = false
	GlobalBtn.AddBtnPress(self)
	GlobalBtn.BtnPress.connect(OnBotInspect)

func OnBotInspect(control_node:Control):
	if control_node != self:
		return
	if !cur_bot_data.is_empty():
		GlobalSignals.ShowPopup.emit("BOT_STAT_INFO",{"bot_uid":cur_bot_data.uid})
	if $locked_slot.visible:
		GlobalSignals.AddNotification.emit({"type":"TEXT","description":"LOCKED SLOT\nUnlock: Skill tree and game progress","color":"WHITE"})

func OnParentReady():
	cur_bot_id = get_index()
	SyncBotData()
	
func SyncBotData():
	_has_bot_to_drag = false
	#Unlock cell
	if cur_bot_id < GlobalStats.GetFreeMergeSlots():
		SetUnlocked(true)
	else:
		SetUnlocked(false)
	cur_bot_data = GlobalSave.GetBotDataFromMergeSlot(cur_bot_id)
	
	if !cur_bot_data.is_empty():
		$rank_color.visible = true
		$rank_color.panel_color = GlobalColor.BotRankToColor(cur_bot_data.rank)
		_has_bot_to_drag = true
		$BotLevel.visible = true
		$BotImage.visible = true
		$BotDPS.visible = true
		$BotImage.SetImageFromBotNum(cur_bot_data.level)
		$BotLevel.text = "LV "+str(cur_bot_data.level).pad_decimals(0)
		$BotDPS.text = Global.CurrencyToString((GlobalStats.GetBotFinalDPSWithGlobalAndStats(cur_bot_data,false,false,true)))+" DPS"
		mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		if !$locked_slot.visible:
			mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			mouse_filter = Control.MOUSE_FILTER_PASS
		$rank_color.visible = false
		$BotImage.visible = false
		$BotDPS.visible = false
		$BotLevel.visible = false
		_has_bot_to_drag = false
	
func _process(_delta: float) -> void:
	is_mouse_inside = get_global_rect().has_point(get_global_mouse_position())
	#Handle start-drag with mouse
	if _has_bot_to_drag:
		
		if is_mouse_inside && Input.is_action_just_pressed("ui_tap") && drag_state == "IDLE":
			last_mouse_pos = get_global_mouse_position()
			drag_state = "WAITING_TO_MAX_DISTANCE"
		if Input.is_action_pressed("ui_tap") && drag_state == "WAITING_TO_MAX_DISTANCE" && last_mouse_pos.distance_to(get_global_mouse_position()) > Global.ACTIVE_DRAG_AFTER_DISTANCE:
			drag_state = "IS_DRAGGING"
			GlobalSignals.StartDragMergeItem.emit(self)
	if drag_state != "IDLE" && !Input.is_action_pressed("ui_tap"):
		drag_state = "IDLE"
	
	#Handle already dragging? dragged into this node
	var drag_in_visible = false
	var default_unlocked_color = "BLUE"
	if Global.cur_dragging_node && Global.mouse_at_sell_node == null:
		if Input.is_action_pressed("ui_tap"):
			#if dragging on self
			if Global.cur_dragging_node.cur_dragging_merge_node == self:
				if is_mouse_inside:
					if _is_unlocked:
						Global.cur_drag_data = {"at_same_merge_node":true}
						drag_in_visible = true
					else:
						drag_in_visible = true
						default_unlocked_color = "ORANGE"
			if Global.cur_dragging_node.cur_dragging_merge_node != self:
				if is_mouse_inside:
					if _is_unlocked:
						Global.cur_drag_data = {"at_other_merge_node":self}
						drag_in_visible = true
					else:
						drag_in_visible = true
						default_unlocked_color = "ORANGE"
	if $IsDragIn.visible != drag_in_visible:
		$IsDragIn.visible = drag_in_visible
	if $IsDragIn.panel_color != default_unlocked_color:
		$IsDragIn.panel_color = default_unlocked_color
		
func SetUnlocked(is_unlocked):
	_is_unlocked = is_unlocked
	if _is_unlocked:
		$locked_slot.visible = false
	else:
		$locked_slot.visible = true

func IsLocked():
	return !_is_unlocked
