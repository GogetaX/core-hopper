extends Node
#ANDROID: ENABLE VIBRATION PERMISION

func VibrateLow():
	if !GlobalSave.save_data.settings.vibration_enabled:
		return
	Input.vibrate_handheld(20)
	
func VibrationMed():
	if !GlobalSave.save_data.settings.vibration_enabled:
		return
	Input.vibrate_handheld(100)
	
func VibrationHigh():
	if !GlobalSave.save_data.settings.vibration_enabled:
		return
	Input.vibrate_handheld(300)

func SFX_Tap():
	pass

func SFX_BlockBreak():
	pass
	
func SFX_CoinReward():
	pass
	
func SFX_CrystalRelicReward():
	pass
	
func SFX_Merge():
	pass
	
func SFX_ChestOpen():
	pass
	
func SFX_Boss():
	pass
	
func SFX_Error():
	pass
	
func CreateSFXNodeAndFree(play_sound_file):
	var s = AudioStreamPlayer.new()
	add_child(s)
	s.bus = "SFX"
	s.stream = load(play_sound_file)
	s.finished.connect(OnFinishedSfx.bind(s))
	s.play()
	
func OnFinishedSfx(sfx:AudioStreamPlayer):
	sfx.queue_free()
	print("finished.")
