extends Control

func InitBossIcon(boss_id):
	var boss_data = GlobalBossDb.GetBossDataByID(boss_id)
	$TextureRect.texture = load("res://data/boss_icons/"+boss_data.boss_icon+".tres")
