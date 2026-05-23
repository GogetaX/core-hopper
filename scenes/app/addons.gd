extends Node

func _ready() -> void:
	InitAds()
	
func InitAds():
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		GlobalAds.Setup($Admob)
