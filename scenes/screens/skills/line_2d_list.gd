extends Node2D

@onready var skill_line = preload("res://scenes/screens/skills/skill_list_line_2d.tscn")
@onready var skill_list = get_parent().get_node("SkillList") as Node2D


func _ready() -> void:
	GlobalSignals.SkillsFinishedCreating.connect(SyncLines)

func SyncLines():
	#Remove all lines
	for x in get_children():
		x.queue_free()
	
	#Init all lines
	for x in skill_list.get_children():
		if !x.cur_skill_data.prereq_ids.is_empty():
			for prereq_id in x.cur_skill_data.prereq_ids:
				var l = skill_line.instantiate() as SkillLineClass
				var prereq_skill_data = GlobalSkillTree.GetSkillData(prereq_id)
				add_child(l)
				var from_pos = Vector2(x.cur_skill_data.pos.x*2,x.cur_skill_data.pos.y*2)
				var to_pos = Vector2(prereq_skill_data.pos.x*2,prereq_skill_data.pos.y*2)
				var from_color = GlobalColor.GetSkillBranchColor(x.cur_skill_data.branch)
				var to_color = GlobalColor.GetSkillBranchColor(prereq_skill_data.branch)
				
				l.InitLine(from_pos,to_pos,from_color,to_color)
	
