extends Control

func InitBossIcon(boss_id):
	var boss_data = GlobalBossDb.GetBossDataByID(boss_id)
	print(boss_data)
