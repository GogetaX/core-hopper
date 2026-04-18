@tool
extends Control
class_name ProgressTabClass
signal OnPressed()

@export var tab_name := "tab name":
	set(value):
		tab_name = value
		if is_node_ready():
			_ready()
	get:
		return tab_name
		
@export_enum("WHITE","BLUE","PURPLE","GOLD") var panel_color := "WHITE":
	set(value):
		panel_color = value
		if is_node_ready():
			_ready()
	get:
		return panel_color
		
@export var tab_group := "progress_tab_group"
@export var default_selected := false:
	set(value):
		default_selected = value
		if is_node_ready():
			_ready()
	get:
		return default_selected
		
@export var notif_counter := 4
var _is_selected = false
var already_loaded = false


func SetNotifCounter(count:int):
	notif_counter = count
	if notif_counter == 0:
		$HList/VBoxContainer/SmallNotifCounter.visible = false
	else:
		$HList/VBoxContainer/SmallNotifCounter.visible = true
		$HList/VBoxContainer/SmallNotifCounter.notif_count = notif_counter
	
func _ready() -> void:
	$HList/Label.text = tab_name
	$SmartPanel.panel_color = panel_color
	$HList/VBoxContainer/SmallNotifCounter.notif_count = notif_counter
	if default_selected:
		$SmartPanel.modulate.a = 1.0
		$HList/Label.self_modulate = GlobalColor.COLOR_TEXT_WHITE
	else:
		$SmartPanel.modulate.a = 0.0
		$HList/Label.self_modulate = GlobalColor.COLOR_DISABLED_TEXT_WHITE
		
	if !Engine.is_editor_hint() && !already_loaded:
		GlobalBtn.AddBtnPress(self)
		GlobalBtn.BtnPress.connect(OnBtnPressed)
		GlobalSignals.OnProgressTabPressed.connect(OnProgressTabPressed)
		_is_selected = default_selected
		already_loaded = true

func OnBtnPressed(btn_control:Control):
	if btn_control != self:
		return
	GlobalSignals.OnProgressTabPressed.emit(self)
	AnimateSelected()
	GlobalMusic.SFX_UITap()
	OnPressed.emit()
	
func TriggerSignal():
	#GlobalMusic.SFX_UITap()
	OnPressed.emit()

func OnProgressTabPressed(btn_node:ProgressTabClass):
	if btn_node != self && btn_node.tab_group == tab_group:
		AnimateUnSelected()

func AnimateSelected():
	if !_is_selected:
		_is_selected = true
		var t = create_tween()
		t.tween_property($SmartPanel,"modulate:a",1.0,0.1)
		t.parallel().tween_property($HList/Label,"self_modulate",Color.WHITE,0.1)
		
func AnimateUnSelected():
	if _is_selected:
		_is_selected = false
		var t = create_tween()
		t.tween_property($SmartPanel,"modulate:a",0.0,0.1)
		t.parallel().tween_property($HList/Label,"self_modulate",GlobalColor.COLOR_DISABLED_TEXT_WHITE,0.1)
		
