@tool
extends Control

@export_enum("BEST_COINS","RECOMENDED","TOO_HARD") var btn_type = "BEST_COINS":
	set(value):
		btn_type = value
		if is_node_ready():
			_ready()
	get:
		return btn_type
		
		
func _ready() -> void:
	InitBtnType()
	$SmartPanel/HBoxContainer/VList/HBoxContainer/recomendation_hint.size.x = $SmartPanel/HBoxContainer/VList/HBoxContainer/recomendation_hint.get_minimum_size().y

func InitBtnType():
	match btn_type:
		"BEST_COINS":
			$SmartPanel/HBoxContainer/IconBG.panel_color = "GOLD"
			$SmartPanel/HBoxContainer/VList/HBoxContainer/recomendation_hint.hash_tag_color = "GOLD"
			$SmartPanel/HBoxContainer/VList/HBoxContainer/recomendation_hint.text = "BEST COINS"
			$SmartPanel/HBoxContainer/VList/ProgressBar.theme_type_variation = "ProgressBarGold"
			$SmartPanel/HBoxContainer/VList/ProgressBar.value = 100
			
		"RECOMENDED":
			$SmartPanel/HBoxContainer/IconBG.panel_color = "BLUE"
			$SmartPanel/HBoxContainer/VList/HBoxContainer/recomendation_hint.hash_tag_color = "BLUE"
			$SmartPanel/HBoxContainer/VList/HBoxContainer/recomendation_hint.text = "RECOMENDED"
			$SmartPanel/HBoxContainer/VList/ProgressBar.theme_type_variation = "ProgressBarBlue"
			$SmartPanel/HBoxContainer/VList/ProgressBar.value = 75
		"TOO_HARD":
			$SmartPanel/HBoxContainer/IconBG.panel_color = "RED"
			$SmartPanel/HBoxContainer/VList/HBoxContainer/recomendation_hint.hash_tag_color = "RED"
			$SmartPanel/HBoxContainer/VList/HBoxContainer/recomendation_hint.text = "TOO HARD"
			$SmartPanel/HBoxContainer/VList/ProgressBar.theme_type_variation = "ProgressBarRed"
			$SmartPanel/HBoxContainer/VList/ProgressBar.value = 25
