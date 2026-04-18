extends Control

@onready var screen_host: Control = $SafeArea/Root/ListContainer/ScreenHost/Scroll

var current_screen: Node = null
var cur_screen_text = ""
var last_opened_scene_str = ""

func _ready() -> void:
	GlobalSignals.OnTabBtnpressed.connect(OnBottomTabPressed)
	GlobalSignals.OpenCloseSettingMenu.connect(OnSettingBtnPress)
	GlobalSignals.OpenTabFromStr.connect(show_tab)
	
	show_tab("DIG")
	InitOfflineData()
	GlobalDailyQuest.InitDailyQuestSystem()
	GlobalStats.InitDailyFreeBot()
	
	
func InitOfflineData():
	var offline_data = GlobalOfflineProgress.ProcessOfflineProgress()
	if !offline_data.is_empty():
		if offline_data.coins == 0 && offline_data.crystals == 0 && offline_data.energy == 0 && offline_data.drop_data == []:
			return
		if offline_data.offline_seconds >= GlobalOfflineProgress.OFFLINE_MIN_SECONDS:
			GlobalSignals.ShowPopup.emit("SHOW_OFFLINE_REWARD",offline_data)
	
func OnSettingBtnPress(to_show:bool):
	if to_show:
		last_opened_scene_str = cur_screen_text
		show_tab("SETTINGS")
	else:
		
		show_tab(last_opened_scene_str)
		last_opened_scene_str = ""
	
	
func OnBottomTabPressed(btn_node:ButtonTabClass):
	show_tab(btn_node.btn_name)

		
	
func show_tab(tab_name:String) -> void:
	if tab_name == cur_screen_text:
		return
	GlobalSignals.StopScreenClick.emit(true)
	var animate = false
	if current_screen:
		animate = true
		current_screen.queue_free()
	cur_screen_text = tab_name
	var new_screen = null
	match tab_name:
		"DIG":
			new_screen = preload("res://scenes/screens/dig/dig_screen.tscn")
			GlobalSignals.SetTopSubTitle.emit("LIVE DIG OPERATIONS")
		"MERGE":
			new_screen = preload("res://scenes/screens/merge/merge_screen.tscn")
			GlobalSignals.SetTopSubTitle.emit("MERGE WORKSHOP")
		"PROGRESS":
			new_screen = preload("res://scenes/screens/progress/progress_screen.tscn")
			GlobalSignals.SetTopSubTitle.emit("PROGRESS HUB")
		"SKILLS":
			new_screen = preload("res://scenes/screens/skills/skills_screen.tscn")
			GlobalSignals.SetTopSubTitle.emit("SKILL TREE")
		"SHOP":
			new_screen = preload("res://scenes/screens/shop/shop_screen.tscn")
			GlobalSignals.SetTopSubTitle.emit("CORE MERCHANT SHOP")
		"SETTINGS":
			new_screen = preload("res://scenes/screens/settings/SettingScreen.tscn")
			GlobalSignals.SetTopSubTitle.emit("SETTINGS & ACCOUNT")

		_:
			print_debug("unknown tab: ",tab_name)
	current_screen = new_screen.instantiate()
	if animate:
		current_screen.modulate.a = 0.0
	#current_screen = SCREEN_SCENES[tab].instantiate()
	screen_host.add_child(current_screen)
	if animate:
		var t = create_tween()
		t.tween_property(current_screen,"modulate:a",1.0,0.1)
		t.finished.connect(func():GlobalSignals.StopScreenClick.emit(false))
	else:
		GlobalSignals.StopScreenClick.emit(false)
