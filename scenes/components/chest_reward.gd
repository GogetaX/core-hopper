extends Control

func InitItem(item_data):
	print(item_data)
	match item_data.source_type:
		"boss":
			$SmartPanel/HBox/VList/source_type.text = "BOSS"
			$SmartPanel/HBox/Control/IconBG.panel_color = "PURPLE"
			$SmartPanel/HBox/VList/HList/ClaimBtn.panel_color = "PURPLE"
			$SmartPanel/HBox/VList/source_name.text = item_data.source_name
			$SmartPanel/HBox/Control/IconBG.icon = GlobalBossDb.GetBossIcon(item_data.source_id)
		_:
			print_debug("Unknown source type: ",item_data.source_type)
