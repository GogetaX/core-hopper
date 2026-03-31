@tool
extends Control

@export_enum("GOLD","PURPLE","BLUE",) var skill_color := "GOLD":
	set(value):
		skill_color = value
		if !is_node_ready():
			await ready
		$SmartPanel/VList/HList/VList2/RewardText.hash_tag_color = skill_color
		match skill_color:
			"BLUE":
				$SmartPanel/VList/ProgressBar.theme_type_variation = "ProgressBarBlue"
			"GOLD":
				$SmartPanel/VList/ProgressBar.theme_type_variation = "ProgressBarGold"
			"PURPLE":
				$SmartPanel/VList/ProgressBar.theme_type_variation = "ProgressBarPurple"
	get:
		return skill_color

@export var quest_title := "QuestTitle":
	set(value):
		quest_title = value
		if !is_node_ready():
			await ready
		$SmartPanel/VList/HList/VList/quest_title.text = quest_title
	get:
		return quest_title

@export var progrss_cur_max = Vector2i.ZERO:
		set(value):
			progrss_cur_max = value
			if !is_node_ready():
				await ready
			$SmartPanel/VList/HList/VList/progress_text.text = str(progrss_cur_max.x)+" / "+str(progrss_cur_max.y)+" complete"
			$SmartPanel/VList/ProgressBar.max_value = progrss_cur_max.y
			$SmartPanel/VList/ProgressBar.value = progrss_cur_max.x
		get:
			return progrss_cur_max

@export var reward_txt := "50.0K AU":
	set(value):
		reward_txt = value
		if !is_node_ready():
			await ready
		$SmartPanel/VList/HList/VList2/RewardText.text = reward_txt
	get:
		return reward_txt
