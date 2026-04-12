extends Control
class_name RelicItemClass

signal OnEquip(is_equiped:bool)

var cur_data = {}

var cur_empty_slot = -1

func SetAsEmpty(empty_slot):
	cur_empty_slot = empty_slot
	HideAllPanels()
	$EmptyItem.visible = true
	GlobalBtn.AddBtnPress(self)
	GlobalBtn.BtnPress.connect(OnEmptyBtnPress)
	
func OnEmptyBtnPress(btn_node:Control):
	if btn_node != self:
		return
	GlobalSignals.ShowPopup.emit("SHOW_RELIC_INV",{"inv_mode":"equip_relic","equip_slot":cur_empty_slot})
	
func SetAsLocked():
	HideAllPanels()
	$LockedItem.visible = true
	
	
func HideAllPanels():
	for x in get_children():
		x.visible = false

func InitItem(item_data:Dictionary,popup_data:Dictionary):
	cur_data = item_data
	HideAllPanels()
	$RelicItem.visible = true
	#print("item data: ")
	#print(item_data)
	$RelicItem/VBoxContainer/HList/VList/relic_name.text = cur_data.db_data.title
	$RelicItem/VBoxContainer/HList/VList/relic_desc.text = cur_data.db_data.description
	$RelicItem/VBoxContainer/HBox/relic_stat.text = GlobalRelicDb.GetEffectStr(cur_data.id,cur_data.save_data.rank) 
	var relic_color = GlobalColor.GetRelicRankColor(cur_data.save_data.rank)
	$RelicItem.panel_color = relic_color
	$RelicItem/VBoxContainer/HList/Control/IconBGCircle.panel_color = relic_color
	$RelicItem/VBoxContainer/HBox/relic_stat.hash_tag_color = relic_color
	$RelicItem/relic_rank.text = str(cur_data.save_data.rank).pad_decimals(0)
	$RelicItem/relic_rank.hash_tag_color = relic_color
	$RelicItem/VBoxContainer/HList/Control/IconBGCircle.icon = GlobalRelicDb.GetRelicIcon(cur_data.db_data.icon)
	$RelicItem/VBoxContainer/RelicBtn.panel_color = relic_color
	var dupes = cur_data.save_data.dupes
	$RelicItem/VBoxContainer/HBox/relic_dupes.visible = false
	$RelicItem/VBoxContainer/HBox/relic_max.visible = false
	if cur_data.save_data.rank < cur_data.db_data.max_rank:
		$RelicItem/VBoxContainer/HBox/relic_dupes.visible = true
		var next_level_dupes = cur_data.db_data.rank_data[str(cur_data.save_data.rank+1).pad_decimals(0)]
		if next_level_dupes.dupes_required <= dupes:
			$RelicItem/VBoxContainer/HBox/relic_dupes.text = "Ready to Rank Up"
			$RelicItem/VBoxContainer/HBox/relic_dupes.hash_tag_color = "PURPLE"
		else:
			$RelicItem/VBoxContainer/HBox/relic_dupes.text = "Next Lv "+str(dupes).pad_decimals(0)+"/"+str(next_level_dupes.dupes_required).pad_decimals(0)
	else:
		$RelicItem/VBoxContainer/HBox/relic_max.visible = true
	if cur_data.is_equipped:
		$RelicItem/VBoxContainer/RelicBtn.buy_btn_title = "UNEQUIP"
	else:
		$RelicItem/VBoxContainer/RelicBtn.buy_btn_title = "EQUIP"
	if popup_data.has("inv_mode"):
		if popup_data.inv_mode == "show_inv":
			$RelicItem/VBoxContainer/RelicBtn.visible = false


func _on_relic_btn_on_pressed() -> void:
	#Equip/unequip
	if !cur_data.is_equipped:
		GlobalRelicDb.EquipRelic(cur_data.id)
		OnEquip.emit(true)
	else:
		GlobalRelicDb.UnequipRelic(cur_data.id)
		OnEquip.emit(false)


func _on_v_box_container_resized() -> void:
	var y_max = $RelicItem/VBoxContainer.get_minimum_size().y
	custom_minimum_size.y = y_max + 30
	#size.y = $RelicItem.custom_minimum_size.y
