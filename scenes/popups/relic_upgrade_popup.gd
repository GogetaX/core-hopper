extends Control

var cur_data := {}

func InitPopup(data:Dictionary):
	cur_data = data
	var owned_relics = GlobalRelicDb.GetAllOwnedRelics()
	HideAll()
	if owned_relics.is_empty():
		$NoRelics.visible = true
		
	else:
		$HasRelics.visible = true
		ShowRelic(owned_relics[0].id)
		
func ShowRelic(relic_id:String):
	var owned_relic_data = GlobalRelicDb.GetOwnedRelicSaveData(relic_id)
	var relic_data = GlobalRelicDb.GetRelicDataByID(relic_id)
	var relic_rank_data = GlobalRelicDb.GetRelicRankData(relic_id,owned_relic_data.rank)
	print(owned_relic_data)
	print(relic_data)
	print("rank data: ")
	print(relic_rank_data)
	var relic_rank_color = GlobalColor.GetRelicRankColor(owned_relic_data.rank)
	
	$HasRelics/Relic/IconBG/relic_rank.text = "RANK "+str(owned_relic_data.rank).pad_decimals(0)
	$HasRelics/Relic/IconBG.icon = GlobalRelicDb.GetRelicIcon(relic_data.icon)
	$HasRelics/Relic/IconBG.panel_color = relic_rank_color
	
	$HasRelics/HList/relic_rarity.hash_tag_color = relic_rank_color
	$HasRelics/HList/relic_rarity.text = relic_data.rarity.to_upper() +" RELIC"
	
	$HasRelics/HList2/relic_name.text = relic_data.title
	
	$HasRelics/Control3/VList/dups/VList/HList/cur_dups.text = str(owned_relic_data.dupes).pad_decimals(0)
	$HasRelics/Control3/VList/dups/VList/progress_bar.max_value = relic_rank_data.dupes_required
	$HasRelics/Control3/VList/dups/VList/progress_bar.value = owned_relic_data.dupes
	
	$HasRelics/Control3/VList/relic_stat/HBoxContainer/from_stat.text = GlobalRelicDb.GetEffectStr(relic_id,owned_relic_data.rank)
	$HasRelics/Control3/VList/relic_stat/HBoxContainer/to_stat.text = GlobalRelicDb.GetEffectStr(relic_id,owned_relic_data.rank+1)
	
	$HasRelics/Control3/VList/relic_stat/HBoxContainer/effect_name.text = relic_data.effect_type
	
	#$HasRelics/Control3/VList/relic_stat/HBoxContainer/effect_icon.icon = GlobalRelicDb.GetEffectIcon(relic_data.effect_type)

	#$HasRelics/Control3/VList/UpgradeBtn.price_text = Global.CurrencyToString(relic_rank_data.upgrade_cost.crystals)
	
func HideAll():
	for x in get_children():
		if x is VBoxContainer:
			x.visible = false

func _on_return_back_btn_pressed() -> void:
	GlobalSignals.ShowPopup.emit("SHOW_RELIC_INV",{"inv_mode":"show_inv"})
