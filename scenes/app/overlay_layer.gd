extends CanvasLayer


var current_screen = null
@onready var screen_host = $Popups/Scroll

func _ready() -> void:
	GlobalSignals.ShowPopup.connect(OnShowPopup)
	GlobalSignals.CloseCurPopup.connect(OnCloseCurPopup)
	visible = true
	$BlurBG.color.a = 0.0
	$BlurBG.visible = false
	screen_host.visible = false
	
func OnCloseCurPopup():
	if current_screen:
		GlobalSignals.StopScreenClick.emit(true)
		var t = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
		t.tween_property($BlurBG,"color:a",0.0,0.2)
		t.parallel().tween_property(current_screen,"modulate:a",0.0,0.2)
		t.finished.connect(FreeCurPopup)

func FreeCurPopup():
	
	current_screen.queue_free()
	GlobalSignals.StopScreenClick.emit(false)
	$BlurBG.visible = false
	screen_host.visible = false
	
func OnShowPopup(popup_str:String,data : Dictionary):
	show_tab(popup_str,data)
	
func show_tab(tab_name:String,data:Dictionary) -> void:
	GlobalSignals.StopScreenClick.emit(true)
	if current_screen:
		current_screen.queue_free()
	var new_screen = null
	match tab_name:
		"WATCH_AD_POPUP":
			new_screen = preload("res://scenes/popups/WatchAdPopup.tscn")
		"SHOW_OFFLINE_REWARD":
			new_screen = preload("res://scenes/popups/OfflineDropPopup.tscn")
		"SHOW_RELIC_INV":
			new_screen = preload("res://scenes/popups/RelicInvPopup.tscn")
		"SHOW_CHESTS":
			new_screen = preload("res://scenes/popups/ChestPopup.tscn")
		"SHOW_CHEST_DROP":
			new_screen = preload("res://scenes/popups/SingleChestPopup.tscn")
		"BOT_STAT_INFO":
			new_screen = preload("res://scenes/popups/BotStatInfoPopup.tscn")
		"UPGRADE_RELIC_POPUP":
			new_screen = preload("res://scenes/popups/RelicUpgradePopup.tscn")
		"CREDIT_SCREEN":
			new_screen = preload("res://scenes/popups/CreditScreenPopup.tscn")
		"SHOW_CORE_RESET":
			new_screen = preload("res://scenes/popups/CoreResetPopup.tscn")
		"OFFLINE_PLANNER":
			new_screen = preload("res://scenes/popups/OfflinePlannerPopup.tscn")
		_:
			print_debug("unknown tab: ",tab_name)
	current_screen = new_screen.instantiate()
	current_screen.modulate.a = 0.0
	
	if tab_name == "SHOW_RELIC_INV":
		current_screen.InitCurPopupData(data)
	
	screen_host.visible = true
	screen_host.add_child(current_screen)
	
	if tab_name == "SHOW_OFFLINE_REWARD":
		current_screen.InitOfflineReward(data)
	elif tab_name == "SHOW_CHEST_DROP":
		current_screen.InitChest(data)
	elif tab_name == "BOT_STAT_INFO":
		current_screen.InitBotInfo(data)
	elif tab_name == "UPGRADE_RELIC_POPUP":
		current_screen.InitPopup(data)
	
	
	
	$BlurBG.visible = true
	var t = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	t.tween_property(current_screen,"modulate:a",1.0,0.2)
	t.parallel().tween_property($BlurBG,"color:a",1.0,0.2)
	t.finished.connect(func():GlobalSignals.StopScreenClick.emit(false))
