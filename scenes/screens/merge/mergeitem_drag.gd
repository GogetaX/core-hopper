extends Control

var cur_dragging_merge_node : MergeItemClass = null
var cur_dragging_bot_node : DigBotClass = null

func SetImageFromMergeItem(merge_node:MergeItemClass):
	cur_dragging_merge_node = merge_node
	$BotImage.SetImageFromBotNum(cur_dragging_merge_node.cur_bot_data.level)
	
func SetImageFromDigBotItem(bot_node:DigBotClass):
	cur_dragging_bot_node =bot_node
	var bot_uid = bot_node.cur_lane_data.bot_uid
	var bot_data = GlobalSave.GetBotDataFromUID(bot_uid)
	$BotImage.SetImageFromBotNum(bot_data.level)
	
