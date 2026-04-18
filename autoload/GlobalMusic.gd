extends Node

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
	var rnd_tap = ["res://audio/sfx/tap_1.ogg","res://audio/sfx/tap_2.ogg","res://audio/sfx/tap_3.ogg"]
	CreateSFXNodeAndFree(rnd_tap.pick_random())

func SFX_UITap():
	CreateSFXNodeAndFree("res://audio/sfx/ui_btn_tap.ogg")
	
func SFX_UIBack():
	CreateSFXNodeAndFree("res://audio/sfx/ui_back.ogg")
	
func SFX_BlockBreak():
	CreateSFXNodeAndFree("res://audio/sfx/BlockBreaking.ogg")
	
func SFX_PickBot():
	CreateSFXNodeAndFree("res://audio/sfx/pick_bot.ogg")
	
func SFX_PlaceBot():
	CreateSFXNodeAndFree("res://audio/sfx/place_bot.ogg")
	
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
	
func CreateSFXNodeAndFree(play_sound_file:String):
	if !GlobalSave.save_data.settings.sfx_enabled:
		return
	var s = AudioStreamPlayer.new()
	add_child(s)
	s.bus = "SFX"
	s.stream = load(play_sound_file)
	s.finished.connect(OnFinishedSfx.bind(s))
	s.play()
	
func OnFinishedSfx(sfx:AudioStreamPlayer):
	sfx.queue_free()
