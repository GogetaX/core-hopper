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
		
@export_enum("WHITE","BLUE","PURPLE","GOLD") var btn_style := "WHITE":
	set(value):
		btn_style = value
		if is_node_ready():
			_ready()
	get:
		return btn_style
		
@export var tab_group := "progress_tab_group"
@export var default_selected := false:
	set(value):
		default_selected = value
		if is_node_ready():
			_ready()
	get:
		return default_selected

var _is_selected = false

func _ready() -> void:
	$HList/Label.text = tab_name
	$SmartPanel.panel_color = btn_style
	$HList/new_notif_count/SmartPanel.panel_color = btn_style
	$HList/new_notif_count.self_modulate = $HList/new_notif_count/SmartPanel.GetTextColor()
	
	if default_selected:
		$SmartPanel.modulate.a = 1.0
		$HList/Label.self_modulate = GlobalColor.COLOR_TEXT_WHITE
	else:
		$SmartPanel.modulate.a = 0.0
		$HList/Label.self_modulate = GlobalColor.COLOR_DISABLED_TEXT_WHITE
		
	if !Engine.is_editor_hint():
		GlobalBtn.AddBtnPress(self)
		GlobalBtn.BtnPress.connect(OnBtnPressed)
		GlobalSignals.OnProgressTabPressed.connect(OnProgressTabPressed)
		_is_selected = default_selected

func OnBtnPressed(btn_control:Control):
	if btn_control != self:
		return
	GlobalSignals.OnProgressTabPressed.emit(self)
	AnimateSelected()
	OnPressed.emit()
	
func TriggerSignal():
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
		
