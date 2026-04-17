extends Control


func _ready() -> void:
	GlobalSignals.DataSaved.connect(SyncData)
	InitCreates()
	SyncData()
	SyncYSize()
	
func InitCreates():
	for x in $SmartPanel/VBoxContainer/VList.get_children():
		if x is WatchAdClass:
			x.WatchAdOpenedOnce.connect(OnWatchAdSuccess)
	
func OnWatchAdSuccess(watch_ad_id:String):
	GlobalWatchAds.ConsumeAdUse(watch_ad_id)
	GlobalSave.SyncSave()
	
func SyncData():
	var watch_data = GlobalWatchAds.GetWatchAdData()
	for x in watch_data:
		var ad_node = $SmartPanel/VBoxContainer/VList.get_node_or_null(x.id) as WatchAdClass
		if ad_node:
			ad_node.icon_big = load(x.icon)
			ad_node.panel_color = x.color
			ad_node.ad_title = x.title
			ad_node.ad_subtitle = x.description
			ad_node.times_per_day = x.times_left
			ad_node.AddRewards(x.rewards)
	
func SyncYSize():
	if !is_node_ready():
		await ready
	await get_tree().process_frame
	var min_size_y = $SmartPanel/VBoxContainer.get_minimum_size().y
	custom_minimum_size.y = min_size_y+60
	size.y = custom_minimum_size.y
	$SmartPanel.position.y = (get_viewport_rect().size.y / 2.0)-(size.y / 2.0)

func _on_close_popup_btn_pressed() -> void:
	GlobalSignals.CloseCurPopup.emit()
