extends CanvasLayer

func _ready() -> void:
	if OS.has_feature("crazygames"):
		visible = true
		GlobalCrazyGames.sdk_ready.connect(OnSDKReady)
		GlobalCrazyGames.InitCrazyGames()
	else:
		visible = false

func OnSDKReady():
	if !GlobalCrazyGames.LoadFromCrazyGames():
		if FileAccess.file_exists(GlobalSave.SAVE_FILE):
			GlobalSave.LoadFromSave()
			GlobalCrazyGames.FlushCrazySave()
		else:
			GlobalSave.save_data = GlobalSave.BuildCleanSaveData()
			GlobalSave.LoadingTimeStamp()
	GlobalCrazyGames.ApplyCrazyGamesAudioSettings()
	GlobalSave.EnsureUpgradeSchema()
	GlobalSave.RepapulateAllLaneBlocks()
	GlobalSignals.GameSaveLoaded.emit()
	GlobalSignals.DataSaved.emit()
	visible = false
