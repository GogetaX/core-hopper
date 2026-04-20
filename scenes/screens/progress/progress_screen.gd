extends VBoxContainer
@onready var upgrade_item = preload("res://scenes/screens/progress/progress_skill.tscn")
@onready var quest_item = preload("res://scenes/screens/progress/quest_item.tscn")
@onready var menu_items = [$Menu_Upgrades,$Menu_Quests,$Menu_Relics]
@onready var expand_btn = preload("res://scenes/screens/progress/smart_single_row_btn.tscn")
@onready var hashtag_label = preload("res://scenes/screens/progress/progress_hash_tag.tscn")

@onready var relic_item = preload("res://scenes/screens/progress/relic_item.tscn")
@onready var locked_relic_item = preload("res://scenes/screens/progress/locked_relic_item.tscn")

var quest_y_size_aim = 0.0
func _ready() -> void:
	GlobalSignals.OnRelicSynced.connect(SyncRelicData)
	HideAllMenus()
	TriggerDefaultSelectedTab()
	InitUpgradeSkillList()
	ShowDifferentTab()
	
func ShowDifferentTab():
	if Global.progress_menu_show_tab == "":
		return
	match Global.progress_menu_show_tab:
		"QUESTS":
			$ProgressTopPanel/VList/Tabs/TabList/TAB_Upgrades.AnimateUnSelected()
			$ProgressTopPanel/VList/Tabs/TabList/TAB_Quests.AnimateSelected()
			_on_tab_quests_on_pressed()
		_:
			print_debug("Unknown Global.progress_menu_show_tab: ",Global.progress_menu_show_tab)
	Global.progress_menu_show_tab = ""
	
func SyncRelicData():
	if $Menu_Relics.visible:
		_on_tab_relics_on_pressed()
		
func InitUpgradeSkillList():
	#Clear upgrade list 
	for x in $Menu_Upgrades/VList/ProgressSkillList.get_children():
		x.queue_free()
	var upgrade_list = GlobalSave.save_data.upgrades
	for x in upgrade_list:
		if upgrade_list[x] is Dictionary:
			var u : UpgradeItemClass = upgrade_item.instantiate()
			
			$Menu_Upgrades/VList/ProgressSkillList.add_child(u)
			u.InitUpgradeItem(x,upgrade_list[x])
			
func TriggerDefaultSelectedTab():
	for x in $ProgressTopPanel/VList/Tabs/TabList.get_children():
		if x is ProgressTabClass:
			if x.default_selected:
				x.TriggerSignal()
func HideAllMenus():
	for x in menu_items:
		x.visible = false

func ShowOnlyMenu(menu_control:Control):
	for x in menu_items:
		if x != menu_control:
			x.visible = false
	menu_control.visible = true
func _on_tab_upgrades_on_pressed() -> void:
	ShowOnlyMenu($Menu_Upgrades)


func _on_tab_quests_on_pressed() -> void:
	ClearAllQuestsItems()
	
	#Show Only 1 Ongoing quest
	var daily_quest = GlobalDailyQuest.GetMostProgressedActiveQuest(true)
	if !daily_quest.is_empty():
		var h = hashtag_label.instantiate() as HashtagClass
		h.hash_tag_color = "BLUE"
		h.no_bg = true
		h.hash_tag_type = "INSIDE_ONLY"
		h.text = "DAILY QUESTS"
		$Menu_Quests/QuestVList/QuestList.add_child(h)
		var q = quest_item.instantiate() as QuestItemClass
		$Menu_Quests/QuestVList/QuestList.add_child(q)
		q.InitDailyQuestItem(daily_quest)
	
	#Show only 1 milestone quest
	var daily_milestone = GlobalMilestone.get_next_milestone()
	if !daily_milestone.is_empty():
		var h = hashtag_label.instantiate() as HashtagClass
		h.hash_tag_color = "GOLD"
		h.no_bg = true
		h.hash_tag_type = "INSIDE_ONLY"
		h.text = "MILESTONE"
		$Menu_Quests/QuestVList/QuestList.add_child(h)
		
		var q = quest_item.instantiate() as QuestItemClass
		$Menu_Quests/QuestVList/QuestList.add_child(q)
		q.InitMilestoneItem(daily_milestone)
	
	#Show purple button: Open full quest list
	var e = expand_btn.instantiate() as ExpandRowButtonClass
	e.button_color = "PURPLE"
	e.btn_text= "Open full quest list"
	$Menu_Quests/QuestVList/QuestList.add_child(e)
	e.OnPress.connect(OnQuestExpand)
	ShowOnlyMenu($Menu_Quests)

func OnQuestExpand():
	ClearAllQuestsItems()
	
	#Show Only 1 Ongoing quest
	var daily_quest_list = GlobalDailyQuest.GetAllActiveQuests()
	if !daily_quest_list.is_empty():
		var h = hashtag_label.instantiate() as HashtagClass
		h.hash_tag_color = "BLUE"
		h.no_bg = true
		h.hash_tag_type = "INSIDE_ONLY"
		h.text = "DAILY QUESTS"
		$Menu_Quests/QuestVList/QuestList.add_child(h)
		for x in daily_quest_list:
			if !x.is_claimed:
				var q = quest_item.instantiate() as QuestItemClass
				$Menu_Quests/QuestVList/QuestList.add_child(q)
				q.InitDailyQuestItem(x)
	
	#Show all active milestone quest
	var daily_milestone_list = GlobalMilestone.get_active_milestones()
	if !daily_milestone_list.is_empty():
		var l = hashtag_label.instantiate() as HashtagClass
		l.hash_tag_color = "GOLD"
		l.no_bg = true
		l.hash_tag_type = "INSIDE_ONLY"
		l.text = "MILESTONE"
		$Menu_Quests/QuestVList/QuestList.add_child(l)
			
		for x in daily_milestone_list:
			if !x.is_claimed:
				var q = quest_item.instantiate() as QuestItemClass
				$Menu_Quests/QuestVList/QuestList.add_child(q)
				q.InitMilestoneItem(x)
	
	#Show purple button: Open full quest list
	var e = expand_btn.instantiate() as ExpandRowButtonClass
	e.button_color = "PURPLE"
	e.btn_text= "Close full quest list"
	$Menu_Quests/QuestVList/QuestList.add_child(e)
	e.OnPress.connect(_on_tab_quests_on_pressed)
	
func ClearAllQuestsItems():
	for x in $Menu_Quests/QuestVList/QuestList.get_children():
		x.queue_free()
		

func _on_tab_relics_on_pressed() -> void:
	#Remove all relics slots
	for x in $Menu_Relics/RelicVList/RelicVList/HFlow.get_children():
		x.queue_free()

	#Populate the unlocked relics
	var avilable_slots = GlobalStats.GetUnlockedRelicSlots()
	var equiped_relics = GlobalRelicDb.GetAllEquippedRelics()
	var max_slots = GlobalRelicDb.MAX_ACTIVE_RELIC_SLOTS
	var cur_slot = 0
	for x in equiped_relics:
		var r = relic_item.instantiate() as RelicItemClass
		$Menu_Relics/RelicVList/RelicVList/HFlow.add_child(r)
		r.InitItem(x,{"inv_mode":"from_equipment","cur_empty_slot":cur_slot})
		r.OnEquip.connect(OnRelicUnequip)
		cur_slot += 1

	
	for x in range(cur_slot,max_slots):
		var r = relic_item.instantiate() as RelicItemClass
		$Menu_Relics/RelicVList/RelicVList/HFlow.add_child(r)
		if x+1 <= avilable_slots:
			r.SetAsEmpty(x)
		else:
			r.SetAsLocked()
		

	ShowOnlyMenu($Menu_Relics)
	
func OnRelicUnequip(is_equiped):
	if !is_equiped:
		GlobalSave.SyncSave()
		GlobalSignals.OnRelicSynced.emit()
		
func _process(delta: float) -> void:
	if $Menu_Quests.visible:
		if quest_y_size_aim != $Menu_Quests.size.y:
			$Menu_Quests.custom_minimum_size.y = lerp($Menu_Quests.custom_minimum_size.y,quest_y_size_aim+30,delta * 10.0)
			$Menu_Quests.size.y = $Menu_Quests.custom_minimum_size.y

func UpgradeListResized() -> void:
	var max_y = $Menu_Upgrades/VList.get_minimum_size().y
	$Menu_Upgrades.custom_minimum_size.y = max_y + 30


func _on_quest_v_list_resized() -> void:
	quest_y_size_aim = $Menu_Quests/QuestVList.get_minimum_size().y
	


func _on_relic_v_list_resized() -> void:
	var max_y = $Menu_Relics/RelicVList.get_minimum_size().y
	$Menu_Relics.custom_minimum_size.y = max_y + 30


func _on_open_relic_inv_btn_on_press() -> void:
	GlobalSignals.ShowPopup.emit("SHOW_RELIC_INV",{"inv_mode":"show_inv"})




func ProgressTopPanelResize() -> void:
	var max_y = $ProgressTopPanel/VList.get_minimum_size().y
	$ProgressTopPanel.custom_minimum_size.y = max_y + 35
	$ProgressTopPanel.size.y = $ProgressTopPanel.custom_minimum_size.y
