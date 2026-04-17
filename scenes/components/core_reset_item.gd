extends Control
class_name CoreResetItemClass

func InitItem(item_data)->void:
	#print(item_data)
	var effect_str = GlobalCoreResetDb.GetCoreResetEffectBonusStr(item_data)
	$HList/effect_name_and_value.text = effect_str
	$HList/IconBG.icon = GlobalSkillTree.GetIconFromStr(item_data.stat)
