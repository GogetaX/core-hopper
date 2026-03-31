extends VBoxContainer
@onready var upgrade_item = preload("res://scenes/screens/progress/progress_skill.tscn")

@onready var menu_items = [$Menu_Upgrades,$Menu_Quests,$Menu_Relics]

func _ready() -> void:
	HideAllMenus()
	TriggerDefaultSelectedTab()
	InitUpgradeSkillList()
	
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
	ShowOnlyMenu($Menu_Quests)


func _on_tab_relics_on_pressed() -> void:
	ShowOnlyMenu($Menu_Relics)


func UpgradeListResized() -> void:
	var max_y = $Menu_Upgrades/VList.get_minimum_size().y
	$Menu_Upgrades.custom_minimum_size.y = max_y + 30
