extends Control

class_name RewardItemClass

func InitRelic(relic_id):
	HideAllContainers()
	$RelicContainer.visible = true
	var relic_data = GlobalRelicDb.GetRelicDataByID(relic_id)
	$RelicContainer/HList/IconBG.icon = GlobalRelicDb.GetRelicIcon(relic_data.icon)
	$RelicContainer/HList/VList/HBoxContainer/relic_name.text = relic_data.title
	$RelicContainer/HList/VList/relic_stat.text = relic_data.description
	
func HideAllContainers():
	for x in get_children():
		x.visible = false
