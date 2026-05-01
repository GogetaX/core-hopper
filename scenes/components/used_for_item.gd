extends HBoxContainer
class_name UsedForClass

func InitItem(icon:Texture2D,desc:String,color_str:String)->void:
	$Label.text = desc
	$IconBG.icon = icon
	$IconBG.panel_color = color_str
	
