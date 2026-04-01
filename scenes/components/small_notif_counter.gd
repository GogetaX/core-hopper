@tool
extends Control

@export_enum("WHITE","GOLD","PURPLE","BLUE","DISABLED","TAB_BG","ORANGE") var panel_color := "PURPLE":
	set(value):
		panel_color = value
		if is_node_ready():
			_ready()
	get:
		return panel_color

@export var notif_count : int = 5:
	set(value):
		notif_count = value
		if is_node_ready():
			_ready()
	get:
		return notif_count

@export var first_notif_as := "!":
	set(value):
		first_notif_as = value
		if is_node_ready():
			_ready()
	get:
		return first_notif_as
	
func _ready():
	if first_notif_as != "" && notif_count == 1:
		$SmartPanel/count.text = first_notif_as
	else:
		$SmartPanel/count.text = str(notif_count)
	$SmartPanel.panel_color = panel_color
