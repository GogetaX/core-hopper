extends Control
class_name ChestItemClass
signal OnPress(item_data:Dictionary)

var cur_item_data = {}
var cur_chest_id = -1

func InitItem(item_data:Dictionary,chest_id:int):
	cur_item_data = item_data
	cur_chest_id = chest_id
	match item_data.source_type:
		"boss":
			$SmartPanel/HBox/VList/source_type.text = "BOSS"
			$SmartPanel/HBox/Control/IconBG.panel_color = "PURPLE"
			$SmartPanel/HBox/VList/HList/ClaimBtn.panel_color = "PURPLE"
			$SmartPanel/HBox/VList/source_name.text = item_data.source_name
			$SmartPanel/HBox/Control/IconBG.icon = GlobalBossDb.GetBossIcon(item_data.source_id)
		_:
			print_debug("Unknown source type: ",item_data.source_type)


func _on_claim_btn_on_pressed() -> void:
	OnPress.emit(cur_item_data,cur_chest_id)
