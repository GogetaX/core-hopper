extends Control

@onready var upgrade_cost_item = preload("res://scenes/popups/upgrade_cost_item.tscn")
@onready var relic_item = preload("res://scenes/popups/relic_upgrade_item.tscn")
var cur_data := {}
var cur_relic_id := ""

func _ready() -> void:
	GlobalSignals.OnRelicUpgradeSelected.connect(OnRelicSelected)
	
func OnRelicSelected(relic_node:RelicUpgradeItemClass):
	InitPopup({"selected_relic_id":relic_node.cur_relic_id})

func InitPopup(data:Dictionary):
	cur_data = data
	var owned_relics = GlobalRelicDb.GetAllOwnedRelics()
	HideAll()
	if owned_relics.is_empty():
		$NoRelics.visible = true
		
	else:
		if cur_data.has("selected_relic_id"):
			$HasRelics.visible = true
			ShowRelic(cur_data.selected_relic_id)
		else:
			$HasRelics.visible = true
			ShowRelic(owned_relics[0].id)
		
func ShowRelic(relic_id:String):
	cur_relic_id = relic_id
	var owned_relic_data = GlobalRelicDb.GetOwnedRelicSaveData(relic_id)
	var relic_data = GlobalRelicDb.GetRelicDataByID(relic_id)
	var relic_rank_data = GlobalRelicDb.GetRelicRankData(relic_id,owned_relic_data.rank)
	
	var relic_rank_color = GlobalColor.GetRelicRankColor(owned_relic_data.rank)
	
	$HasRelics/Relic/IconBG/relic_rank.text = "RANK "+str(owned_relic_data.rank).pad_decimals(0)
	$HasRelics/Relic/IconBG.icon = GlobalRelicDb.GetRelicIcon(relic_data.icon)
	$HasRelics/Relic/IconBG.panel_color = relic_rank_color
	$HasRelics/Relic/IconBG/relic_rank.hash_tag_color = relic_rank_color
	
	$HasRelics/HList/relic_rarity.hash_tag_color = relic_rank_color
	$HasRelics/HList/relic_rarity.text = relic_data.rarity.to_upper() +" RELIC"
	
	$HasRelics/HList2/relic_name.text = relic_data.title
	
	$HasRelics/Control3/VList/dups/VList/HList/max_dups.text = str(relic_rank_data.dupes_required).pad_decimals(0)
	$HasRelics/Control3/VList/dups/VList/HList/cur_dups.text = str(owned_relic_data.dupes).pad_decimals(0)
	$HasRelics/Control3/VList/dups/VList/progress_bar.max_value = relic_rank_data.dupes_required
	$HasRelics/Control3/VList/dups/VList/progress_bar.value = owned_relic_data.dupes
	
	$HasRelics/Control3/VList/relic_stat/HBoxContainer/from_stat.text = GlobalRelicDb.GetEffectStr(relic_id,owned_relic_data.rank)
	$HasRelics/Control3/VList/relic_stat/HBoxContainer/to_stat.text = GlobalRelicDb.GetEffectStr(relic_id,owned_relic_data.rank+1)
	
	$HasRelics/Control3/VList/relic_stat/HBoxContainer/effect_name.text = GlobalRelicDb.GetEffectTypeDescription(relic_data.effect_type)
	$HasRelics/Control3/VList/relic_stat/HBoxContainer/effect_icon.icon = Global.GetIconFromStr(relic_data.effect_type)
	
	#Remove old upgrade cost
	for x in $HasRelics/Control3/VList/UpgradeCost.get_children():
		x.queue_free()
	#Populate new upgrade cost items
	var has_enough_resource = true
	for x in relic_rank_data.upgrade_cost:
		if relic_rank_data.upgrade_cost[x] > 0:
			var u = upgrade_cost_item.instantiate() as UpgradeCostItemClass
			$HasRelics/Control3/VList/UpgradeCost.add_child(u)
			u.InitCost(x,relic_rank_data.upgrade_cost[x])
			if !u.HasEnough():
				has_enough_resource = false
 	
	#Remove all relic items
	for x in $HasRelics/Control3/VList/Scroll/RelicFlow.get_children():
		x.queue_free()
	#Repopulate all the owned relics 
	var owned_relic_list = GlobalRelicDb.GetAllOwnedRelics()
	for x in owned_relic_list:
		var r = relic_item.instantiate() as RelicUpgradeItemClass
		$HasRelics/Control3/VList/Scroll/RelicFlow.add_child(r)
		r.InitOwnedItem(x.id)
		if relic_id == x.id:
			r.SetAsSelected()
	
	var upgrade_disabled = true
	$HasRelics/Control3/VList/relic_at_max_label.visible = false
	$HasRelics/Control3/VList/relic_stat/HBoxContainer/double_arrow.visible = false
	
	if owned_relic_data.dupes >= relic_rank_data.dupes_required:
		$HasRelics/Control3/VList/dups/VList/HList/cur_dups.hash_tag_color = "BLUE"
	else:
		
		$HasRelics/Control3/VList/dups/VList/HList/cur_dups.hash_tag_color = "RED"

	if owned_relic_data.rank == relic_data.max_rank:
		$HasRelics/Control3/VList/relic_stat/HBoxContainer/double_arrow.visible = false
		$HasRelics/Control3/VList/UpgradeBtn.visible = false
		$HasRelics/Control3/VList/relic_at_max_label.visible = true
	else:
		$HasRelics/Control3/VList/relic_stat/HBoxContainer/double_arrow.visible = true
		$HasRelics/Control3/VList/UpgradeBtn.visible = true
		$HasRelics/Control3/VList/relic_at_max_label.visible = false
		if owned_relic_data.dupes >= relic_rank_data.dupes_required && has_enough_resource:
			upgrade_disabled = false
			
	$HasRelics/Control3/VList/UpgradeBtn.SetDisabled(upgrade_disabled)
		
func HideAll():
	for x in get_children():
		if x is VBoxContainer:
			x.visible = false

func _on_return_back_btn_pressed() -> void:
	GlobalMusic.SFX_UIBack()
	GlobalSignals.ShowPopup.emit("SHOW_RELIC_INV",{"inv_mode":"show_inv"})


func _on_upgrade_btn_on_pressed() -> void:
	if GlobalRelicDb.CanUpgradeOwned(cur_relic_id):
		GlobalRelicDb.UpgradeRelicByID(cur_relic_id)
		GlobalSave.SyncSave()
		InitPopup({"selected_relic_id":cur_relic_id})
		GlobalSignals.OnRelicSynced.emit()
