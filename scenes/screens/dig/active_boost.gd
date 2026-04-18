extends Control

var cur_boost_id := ""

func _ready() -> void:
	GlobalSignals.DataSaved.connect(SyncBoost)
	SyncBoost()
	
func SyncBoost():
	HideAllPanels()
	$CurActiveBoost/active_boost_tick.stop()
	var activated_boost_id = GlobalTimedBonus.GetActivatedBoosterIds()
	if activated_boost_id.is_empty():
		$NoActiveBoost.visible = true
	else:
		$CurActiveBoost.visible = true
		var cur_boost = activated_boost_id[0]
		cur_boost_id = cur_boost
		var active_boost = GlobalTimedBonus.GetActivatedBoosterData(cur_boost)
		if active_boost.effect_value == 1.0:
			$CurActiveBoost/VList/boost_value.visible = false
		else:
			$CurActiveBoost/VList/boost_value.visible = true
		$CurActiveBoost/VList/HBoxContainer/boost_name.text = active_boost.title
		$CurActiveBoost/VList/boost_value.text = "x"+str(active_boost.effect_value).pad_decimals(1)
		$CurActiveBoost/VList/HBoxContainer/boost_time_left.text = Global.SecondsToPrettyTimeString(active_boost.remaining_sec)
		$CurActiveBoost/active_boost_tick.start()
		$CurActiveBoost/VList/boost_desc.text = active_boost.description
		_on_active_boost_tick_timeout()
		
func HideAllPanels():
	for x in get_children():
		x.visible = false


func _on_active_boost_tick_timeout() -> void:
	if cur_boost_id != "":
		if GlobalTimedBonus.IsBoosterActive(cur_boost_id):
			var active_boost = GlobalTimedBonus.GetActivatedBoosterData(cur_boost_id)
			$CurActiveBoost/VList/HBoxContainer/boost_time_left.text = Global.SecondsToPrettyTimeString(active_boost.remaining_sec)
		else:
			SyncBoost()
