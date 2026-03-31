@tool
extends Control


@export_enum("WHITE","GOLD","PURPLE","BLUE","DISABLED","TAB_BG","ORANGE") var panel_color := "PURPLE":
	set(value):
		panel_color = value
		if is_node_ready():
			_ready()
	get:
		return panel_color
		
@export var icon_big : Texture2D = null:
	set(value):
		icon_big = value
		if is_node_ready():
			_ready()
	get:
		return icon_big
		
@export var ad_title := "Instant Hyper-Dig":
	set(value):
		ad_title = value
		if is_node_ready():
			_ready()
	get:
		return ad_title

@export var ad_subtitle := "30M RESOURCE CACHE":
	set(value):
		ad_subtitle = value
		if is_node_ready():
			_ready()
	get:
		return ad_subtitle
		
func _ready() -> void:
	$SmartPanel/VList/HList/IconBG.panel_color = panel_color
	$SmartPanel/VList/HList/VList/ad_subtitle.hash_tag_color = panel_color
	$SmartPanel/VList/WatchAdBtn.panel_color = panel_color
	$SmartPanel/VList/HList/IconBG.icon = icon_big
	$SmartPanel/VList/HList/VList/ad_title.text = ad_title
	$SmartPanel/VList/HList/VList/ad_subtitle.text = ad_subtitle
	
