extends Node

func _ready() -> void:
	InitAds()
	
func InitAds():
	if OS.get_name() == "Android":
		GlobalAds.Setup($Admob)
