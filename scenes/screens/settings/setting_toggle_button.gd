@tool
extends Control

signal IsToggled(toggled_on:bool)

@export_enum("WHITE","GOLD","PURPLE","BLUE","DISABLED","TAB_BG","ORANGE") var panel_color := "PURPLE":
	set(value):
		panel_color = value
		if is_node_ready():
			_ready()
	get:
		return panel_color
		
@export var setting_icon : Texture2D = null:
	set(value):
		setting_icon = value
		if is_node_ready():
			_ready()
	get:
		return setting_icon
		
@export var setting_title := "Music":
	set(value):
		setting_title = value
		if is_node_ready():
			_ready()
	get:
		return setting_title

@export var setting_subtitle := "Background Ambience":
	set(value):
		setting_subtitle = value
		if is_node_ready():
			_ready()
	get:
		return setting_subtitle
		
func _ready() -> void:
	$SmartPanel/HList/VList/setting_title.text = setting_title
	$SmartPanel/HList/VList/setting_subtitle.text = setting_subtitle
	$SmartPanel/HList/IconBG.panel_color = panel_color
	$SmartPanel.panel_color = panel_color
	$SmartPanel/HList/IconBG.icon = setting_icon
	if !Engine.is_editor_hint():
		$SmartPanel/HList/VList2/SettingToggle.IsToggled.connect(_SetAsToggled)

func _SetAsToggled(is_toggled:bool):
	IsToggled.emit(is_toggled)
	
func SetSelected(is_selected):
	$SmartPanel/HList/VList2/SettingToggle.SetEnabled(is_selected)
