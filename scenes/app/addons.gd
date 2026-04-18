extends Node

func _ready() -> void:
	InitAds()
	
func InitAds():
	if OS.get_name() == "Android":
		$Admob.initialize()
		


func _on_admob_initialization_completed(_status_data: InitializationStatus) -> void:
	GlobalAds.admob_plugin = $Admob
