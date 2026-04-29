extends Panel

const MAX_BLOCKS_PER_SPAWM = 5

@onready var BlockMaterial = preload("res://scenes/screens/dig/material.tscn")

@onready var lane_0_list = $VList/HList2/VList1/Panel/VBoxContainer/Lane_0_List
@onready var lane_1_list = $VList/HList2/VList2/Panel/VBoxContainer/Lane_1_List
@onready var lane_2_list = $VList/HList2/VList3/Panel/VBoxContainer/Lane_2_List
@onready var lane_3_list = $VList/HList2/VList4/Panel/VBoxContainer/Lane_3_List
@onready var lane_4_list = $VList/HList2/VList5/Panel/VBoxContainer/Lane_4_List


var _shown_boss_uid_by_lane := {}

@export var test_boss_id := ""

func _ready() -> void:
	GlobalSignals.DataSaved.connect(OnDataUpdated)
	GlobalSignals.GameSaveLoaded.connect(OnDataUpdated)
	_ApplyTestBossIfNeeded()
	OnDataUpdated()
	
	


func _ApplyTestBossIfNeeded() -> void:
	if test_boss_id.strip_edges() == "":
		return

	# Keep this from accidentally affecting release builds.
	if !OS.is_debug_build():
		return

	if GlobalSave.save_data.lanes.is_empty():
		return

	var lane_index := 0
	var lane = GlobalSave.save_data.lanes[lane_index]

	if lane.block_data.is_empty():
		return

	var normal_block: Dictionary = lane.block_data[0]

	var depth := int(normal_block.get("depth", lane.get("lane_depth", 1)))
	depth = max(1, depth)

	var normal_hp = normal_block.get("max_hp", normal_block.get("hp", 1.0))
	var normal_reward := int(normal_block.get("reward_amount", 0))

	var boss_block := GlobalBossDb.GenerateBossBlockByID(
		test_boss_id.strip_edges(),
		depth,
		lane_index,
		normal_hp,
		normal_reward
	)

	if boss_block.is_empty():
		push_warning("Test boss failed. Unknown boss_id: " + test_boss_id)
		return

	lane.block_data[0] = boss_block

	# Optional, but useful if UI is already connected.
	if GlobalDiggingProcess.has_method("_EmitBlockHpUpdated"):
		GlobalDiggingProcess._EmitBlockHpUpdated(lane_index)
		
func SyncLane(lane_list: VBoxContainer) -> void:
	var lane_index = int(str(lane_list.name).split("_")[1])
	var lane_data = GlobalSave.GetLaneData(lane_index)

	var need_rebuild := false
	
	if lane_list.get_child_count() != lane_data.block_data.size():
		need_rebuild = true
		
	else:
		
		for i in range(lane_data.block_data.size()):
			var block_data = lane_data.block_data[i]
			var child = lane_list.get_child(i)

			if !child.has_method("GetUID"):
				need_rebuild = true
				
				break

			if str(child.GetUID()) != str(block_data.uid):
				need_rebuild = true
				
				break

	if need_rebuild:
		for c in lane_list.get_children():
			c.queue_free()

		for block_data in lane_data.block_data:
			var b = BlockMaterial.instantiate() as MaterialClass
			lane_list.add_child(b)
			b.InitData(block_data)
			
	else:
		for i in range(lane_data.block_data.size()):
			var block_data = lane_data.block_data[i]
			var child = lane_list.get_child(i)
			if child.has_method("InitData"):
				child.InitData(block_data)

	_CheckBossRevealForLane(lane_index, lane_data)
	
func OnDataUpdated():
	#Find a lane that has no data left, populate it based on current depth of the lane
	SyncLane(lane_0_list)
	SyncLane(lane_1_list)
	SyncLane(lane_2_list)
	SyncLane(lane_3_list)
	SyncLane(lane_4_list)

	
func _on_watch_ad_btn_btn_pressed() -> void:
	GlobalSignals.ShowPopup.emit("WATCH_AD_POPUP",{})


func _CheckBossRevealForLane(lane_index: int, lane_data: Dictionary) -> void:
	if lane_data.block_data.is_empty():
		_shown_boss_uid_by_lane.erase(lane_index)
		return

	var front_block = lane_data.block_data[0]

	if !bool(front_block.get("is_boss", false)):
		_shown_boss_uid_by_lane.erase(lane_index)
		return

	var boss_uid := str(front_block.get("uid", ""))
	if boss_uid == "":
		return

	if _shown_boss_uid_by_lane.get(lane_index, "") == boss_uid:
		return

	_shown_boss_uid_by_lane[lane_index] = boss_uid
	ShowBossIntro(lane_index, front_block)
	
func ShowBossIntro(_lane_index: int, boss_block: Dictionary) -> void:
	#print("Boss appeared on lane ", lane_index, ": ", boss_block.get("name", "Boss"))
	GlobalSignals.AddNotification.emit({"type":"TEXT","description":"Boss appeared!\n"+boss_block.get("name", "Boss"),"color":"ORANGE"})

	# Example UI:
	# $BossBanner.show()
	# $BossBanner/NameLabel.text = str(boss_block.get("name", "Boss"))
	# $BossBanner/DepthLabel.text = str(boss_block.get("depth", 0)) + "m"
