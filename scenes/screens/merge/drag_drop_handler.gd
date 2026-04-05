extends Node

@onready var merge_drag_item = preload("res://scenes/screens/merge/mergeitem_drag.tscn")


var merge_drag_node = null

func _ready() -> void:
	GlobalSignals.StartDragMergeItem.connect(OnStartDragMergeItem)
	GlobalSignals.StartDragBotItem.connect(OnStartDragBotItem)
	
func OnStartDragBotItem(bot_item:DigBotClass):
	merge_drag_node = merge_drag_item.instantiate()
	merge_drag_node.SetImageFromDigBotItem(bot_item)
	add_child(merge_drag_node)
	Global.cur_dragging_node = merge_drag_node
	
func OnStartDragMergeItem(merge_item:MergeItemClass):
	merge_drag_node = merge_drag_item.instantiate()
	merge_drag_node.SetImageFromMergeItem(merge_item)
	add_child(merge_drag_node)
	Global.cur_dragging_node = merge_drag_node
	
func _process(_delta: float) -> void:
	if merge_drag_node:
		merge_drag_node.global_position = get_viewport().get_mouse_position()-(merge_drag_node.size / 2.0)
		if !Input.is_action_pressed("ui_tap"):
			if merge_drag_node.cur_dragging_merge_node:
				EvaluateReleaseStateFromMerge()
			elif merge_drag_node.cur_dragging_bot_node:
				EvaluateReleaseStateFromDigbot()
			else:
				print_debug("Issue With evaluation of current dragging.")
				
			Global.cur_drag_data = {}
			Global.cur_dragging_node.queue_free()

func EvaluateReleaseStateFromDigbot():
	if Global.cur_drag_data.has("at_self_dig_bot"):
		var is_mouse_in = merge_drag_node.cur_dragging_bot_node.get_global_rect().has_point(get_viewport().get_mouse_position())
		if is_mouse_in:
			#print("mouse in same node (cancel)")
			return
	elif Global.cur_drag_data.has("at_other_merge_node"):
		var is_mouse_in = Global.cur_drag_data.at_other_merge_node.get_global_rect().has_point(get_viewport().get_mouse_position())
		if is_mouse_in:
			var source_dig : DigBotClass = merge_drag_node.cur_dragging_bot_node
			var target_merge : MergeItemClass = Global.cur_drag_data.at_other_merge_node
			var source_bot_data = GlobalSave.GetBotDataFromUID(source_dig.cur_lane_data.bot_uid)
			if target_merge.cur_bot_data == {}:
				#print("mouse in, move from dig-bot into merge")
				source_bot_data.merge_slot_id = target_merge.cur_bot_id
				source_dig.cur_lane_data.bot_uid = -1
				GlobalSave.SyncSave()
			elif target_merge.cur_bot_data.level == source_bot_data.level:
				GlobalSave.MergeFromDigBotToMerge(source_dig.cur_lane_data.bot_uid,target_merge.cur_bot_data.uid)
				GlobalSave.SetTotalMerges(1)
				GlobalSave.SyncSave()
				#print("mouse in, dig-bot and merge bot has same level, should merge them togeather into MERGE slot.")
			else:
				GlobalSave.SwapBetween2BotsDigBoToMerge(source_dig.cur_lane_data.bot_uid,target_merge.cur_bot_data.uid)
				GlobalSave.SyncSave()
				print("mouse in, should swap bots.")
	elif Global.cur_drag_data.has("at_other_dig_bot"):
		var orig_bot : DigBotClass = merge_drag_node.cur_dragging_bot_node
		var target_bot : DigBotClass = Global.cur_drag_data.at_other_dig_bot
		var orig_bot_data = GlobalSave.GetBotDataFromUID(orig_bot.cur_lane_data.bot_uid)
		var target_bot_data = GlobalSave.GetBotDataFromUID(target_bot.cur_lane_data.bot_uid)
		if target_bot_data.is_empty():
			#Move Bot from one lane_index to another
			var target_lane_data = GlobalSave.GetLaneDataByIndex(target_bot.cur_lane)
			var orig_lane_data = GlobalSave.GetLaneDataByIndex(orig_bot.cur_lane)
			target_lane_data.bot_uid = orig_bot_data.uid
			orig_lane_data.bot_uid = -1
			GlobalSave.SyncSave()
			print("Move to empty DigBot")
			
		elif orig_bot_data.level == target_bot_data.level:
			target_bot_data.level += 1
			GlobalSave.SetHighestBotLevel(target_bot_data.level)
			GlobalSave.RemoveBotByID(orig_bot.cur_lane_data.bot_uid)
			GlobalSave.SetTotalMerges(1)
			GlobalSave.SyncSave()
			#print("Merge between DigBot -> DigBot")
		else:
			var orig_bot_uid = orig_bot.cur_lane_data.bot_uid
			var target_bot_uid = target_bot.cur_lane_data.bot_uid
			orig_bot.cur_lane_data.bot_uid = target_bot_uid
			target_bot.cur_lane_data.bot_uid = orig_bot_uid
			GlobalSave.SyncSave()
			#print("Swap Between Dig Bot -> Dig Bot")
				
func EvaluateReleaseStateFromMerge():
	if Global.cur_drag_data.has("at_same_merge_node"):
		var is_mouse_in = merge_drag_node.cur_dragging_merge_node.get_global_rect().has_point(get_viewport().get_mouse_position())
		if is_mouse_in:
			#print("mouse in same node (cancel)")
			return
	elif Global.cur_drag_data.has("at_other_merge_node"):
		var merge_node = Global.cur_drag_data.at_other_merge_node as MergeItemClass
		if !merge_node.IsLocked():
			var is_mouse_in = Global.cur_drag_data.at_other_merge_node.get_global_rect().has_point(get_viewport().get_mouse_position())
			if is_mouse_in:
				if merge_node.cur_bot_data == {}:
					var orig_drag_node = merge_drag_node.cur_dragging_merge_node as MergeItemClass
					#print("mouse in other merge node, should move to other merge item")
					var bot_db = GlobalSave.GetBotDataFromMergeSlot(orig_drag_node.cur_bot_id)
					bot_db.merge_slot_id = int(merge_node.cur_bot_id)
					GlobalSave.SyncSave()
					return
				else:
					if merge_node.cur_bot_data.level == Global.cur_dragging_node.cur_dragging_merge_node.cur_bot_data.level:
						#print("mouse in, should merge them at merge_node")
						var orig_merge_node :MergeItemClass = Global.cur_dragging_node.cur_dragging_merge_node
						var target_merge_node : MergeItemClass = merge_node
						GlobalSave.CombineBetween2MergeNodes(orig_merge_node.cur_bot_data.uid,target_merge_node.cur_bot_data.uid)
						GlobalSave.SetTotalMerges(1)
						GlobalSave.SyncSave()
					else:
						var orig_merge_node :MergeItemClass = Global.cur_dragging_node.cur_dragging_merge_node
						var target_merge_node : MergeItemClass = merge_node
						GlobalSave.SwapBetween2BotsMergeToMerge(orig_merge_node.cur_bot_data.uid,target_merge_node.cur_bot_data.uid)
						GlobalSave.SyncSave()
						#print("mouse in, should swap between them")
		else:
			return
			#print("mouse in, but merge bot is Locked.")
	elif Global.cur_drag_data.has("at_self_dig_bot"):
		#print("mouse in at same DigBot, should not do anything.")
		return
	elif Global.cur_drag_data.has("at_other_dig_bot"):
		var dig_node = Global.cur_drag_data.at_other_dig_bot as DigBotClass
		var is_mouse_in = dig_node.get_global_rect().has_point(get_viewport().get_mouse_position())
		if is_mouse_in:
			if dig_node.cur_lane_data.bot_uid == -1:
				#print("mouse in, dig_node, should move to dig node")
				var orig_drag_node = merge_drag_node.cur_dragging_merge_node as MergeItemClass
				var to_dig_bot = dig_node as DigBotClass
				var bot_data = GlobalSave.GetBotDataFromMergeSlot(orig_drag_node.cur_bot_id)
				var to_lane_data = GlobalSave.GetLaneData(to_dig_bot.cur_lane)
				bot_data.merge_slot_id = int(-1)
				to_lane_data.bot_uid = int(bot_data.uid)
				GlobalSave.SyncSave()
				
			else:
				var bot_data = GlobalSave.GetBotDataFromUID(dig_node.cur_lane_data.bot_uid)
				if bot_data == {}:
					return
					#print("has uid but no data about it?! ",dig_node.cur_lane_data.bot_uid)
				elif bot_data.level == Global.cur_dragging_node.cur_dragging_merge_node.cur_bot_data.level:
					var source_merge : MergeItemClass = merge_drag_node.cur_dragging_merge_node
					var target_digbot : DigBotClass = dig_node
					GlobalSave.MergeFromMergeToDigBot(source_merge.cur_bot_data.uid,target_digbot.cur_lane_data.bot_uid)
					GlobalSave.SetTotalMerges(1)
					GlobalSave.SyncSave()
					#print("mouse in, should merge from MergeItem -> BotItem")
				else:
					#print("mouse in, should swap MergeItem -> BotItem")
					var selected_merge_item : MergeItemClass = Global.cur_dragging_node.cur_dragging_merge_node
					var target_dig_bot : DigBotClass = Global.cur_drag_data.at_other_dig_bot
					GlobalSave.SwapBetween2BotsMergeToDigBot(selected_merge_item.cur_bot_data.uid,target_dig_bot.cur_lane_data.bot_uid)
					GlobalSave.SyncSave()
#at_self_dig_bot, at_other_dig_bot, DigBotClass
