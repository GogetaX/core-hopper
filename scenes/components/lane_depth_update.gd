extends Node

var cur_lane = -1
func _ready() -> void:
	get_parent().ready.connect(SyncCurLane)
	GlobalSignals.DataSaved.connect(SyncCurLane)
	GlobalDiggingProcess.block_destroyed.connect(OnBlockDestroyed)
	SyncCurLane()
	
func OnBlockDestroyed(lane_index: int, _block_uid: String):
	if lane_index == cur_lane:
		SyncCurLane()
		
func SyncCurLane():
	await get_tree().process_frame
	if cur_lane == -1:
		var l = str(get_parent().name).split("_")
		cur_lane = int(l[1])
	var lane_data = GlobalSave.GetLaneData(cur_lane)
	if !lane_data.is_empty():
		get_parent().hash_tag_text = str(lane_data.lane_depth).pad_decimals(0)
