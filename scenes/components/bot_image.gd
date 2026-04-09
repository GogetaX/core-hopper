extends TextureRect

func _NumToStr(_bot_num):
	if _bot_num <= 0:
		_bot_num = 1
	var cur_num = str(_bot_num)
	if cur_num.length() == 1:
		cur_num = "0"+cur_num
	return cur_num

func SetImageFromBotNum(_bot_num:int):
	var bot_num_str = _NumToStr(_bot_num)
	texture = load("res://data/bot_atlas/bot_"+bot_num_str+".tres")
	
