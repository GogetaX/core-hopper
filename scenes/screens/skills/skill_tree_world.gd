extends Node2D

@onready var skill_world_item = preload("res://scenes/screens/skills/skill_tree_world_item.tscn")

func _ready() -> void:
	InitSkillTree()

func InitSkillTree():
	#Remove all skill list
	for x in $SkillList.get_children():
		x.queue_free()
		
	#Create all skills on screen
	var all_skill_nodes = GlobalSkillTree.GetAllSkillNodes()
	for x in all_skill_nodes:
		var s = skill_world_item.instantiate() as WorldSkillClass
		$SkillList.add_child(s)
		if Global.last_skill_key_selected == "":
			Global.last_skill_key_selected = x
		s.InitSkill(x,all_skill_nodes[x])
		
	
	await get_tree().process_frame
	GlobalSignals.SkillsFinishedCreating.emit()
	
func GetCurSelectedSkill():
	for x in $SkillList.get_children():
		if x is WorldSkillClass:
			if x.IsSelected():
				return x
	return null

func GetSkillLimitRect():
	var max_left = 0
	var max_right = 0
	var max_top = 0
	var max_bottom = 0
	for x in $SkillList.get_children():
		if x is WorldSkillClass:
			if x.global_position.x < max_left:
				max_left = x.global_position.x
			if x.global_position.x > max_right:
				max_right = x.global_position.x
			if x.global_position.y < max_top:
				max_top = x.global_position.y
			if x.global_position.y > max_bottom:
				max_bottom = x.global_position.y
	return Rect2i(max_left,max_right,max_top,max_bottom)
