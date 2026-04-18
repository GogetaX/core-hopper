extends CanvasLayer

func _ready() -> void:
	if OS.has_feature("crazygames"):
		visible = true
		GlobalCrazyGames.sdk_ready.connect(OnSDKReady)
		GlobalCrazyGames.InitCrazyGames()
	else:
		visible = false

func OnSDKReady():
	GlobalCrazyGames.LoadFromCrazyGames()
	GlobalSave.SyncSave(false)
	visible = false
