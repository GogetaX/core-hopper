extends VBoxContainer

const MAX_BLOCKS_PER_SPAWM = 5

@onready var BlockMaterial = preload("res://scenes/screens/dig/material.tscn")

@onready var lane_0_list = $MiningPanel/VList/HList2/VList1/Panel/VBoxContainer/Lane_0_List
@onready var lane_1_list = $MiningPanel/VList/HList2/VList2/Panel/VBoxContainer/Lane_1_List
@onready var lane_2_list = $MiningPanel/VList/HList2/VList3/Panel/VBoxContainer/Lane_2_List
@onready var lane_3_list = $MiningPanel/VList/HList2/VList4/Panel/VBoxContainer/Lane_3_List
@onready var lane_4_list = $MiningPanel/VList/HList2/VList5/Panel/VBoxContainer/Lane_4_List

func _ready() -> void:
	GlobalSignals.DataSaved.connect(OnDataUpdated)
	OnDataUpdated()
	

func OnDataUpdated():
	#Find a lane that has no data left, populate it based on current depth of the lane
	PopulateLane(lane_0_list)
	PopulateLane(lane_1_list)
	PopulateLane(lane_2_list)
	PopulateLane(lane_3_list)
	PopulateLane(lane_4_list)
	

	
func PopulateLane(lane_list:VBoxContainer):
	await get_tree().process_frame
	var lane_index = int(str(lane_list.name).split("_")[1])

	var lane_data = GlobalSave.GetLaneData(lane_index)
	if lane_list.get_child_count() == 0:
		for x in lane_data.block_data:
			var b = BlockMaterial.instantiate() as MaterialClass
			b.InitData(x)
			lane_list.add_child(b)
			
	
func _on_watch_ad_btn_btn_pressed() -> void:
	GlobalSignals.ShowPopup.emit("WATCH_AD_POPUP",{})


func _on_lane_1_list_child_exiting_tree(_node: Node) -> void:
	PopulateLane(lane_0_list)


func _on_lane_2_list_child_exiting_tree(_node: Node) -> void:
	PopulateLane(lane_1_list)


func _on_lane_3_list_child_exiting_tree(_node: Node) -> void:
	PopulateLane(lane_2_list)


func _on_lane_4_list_child_exiting_tree(_node: Node) -> void:
	PopulateLane(lane_3_list)


func _on_lane_5_list_child_exiting_tree(_node: Node) -> void:
	PopulateLane(lane_4_list)
