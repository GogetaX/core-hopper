extends Node2D


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
