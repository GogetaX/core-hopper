extends VBoxContainer

func _ready() -> void:
	GlobalSignals.DataSaved.connect(OnDataSaved)
	OnDataSaved()
	
func OnDataSaved():
	var next_reset_data = GlobalCoreResetDb.GetNextResetData()
	$Panel/VBoxContainer/reset_title.text = next_reset_data.title
	$Panel/VBoxContainer/reset_depth.text = Global.FormatNumberWithCommas(next_reset_data.required_depth)+"m"
	var reward_str = GlobalCoreResetDb.GetNextResetBonusStr("+")
	$Panel/VBoxContainer/unlock_text.text = reward_str
