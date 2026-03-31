extends Node

@export_enum("FLOAT","INT","STRING") var expected_data_type := "INT"
@export_enum("NONE","CURRENCY") var str_format := "NONE"
@export var listen_to_save_data := "progress.global_depth"
@export var added_end_text = ""
var _cur_list = []

func _ready() -> void:
	GlobalSignals.DataSaved.connect(SyncData)
	get_parent().ready.connect(SyncData)
	
func SyncData():
	await get_tree().process_frame
	_cur_list = listen_to_save_data.split(".")
	var val = GetVal(GlobalSave.save_data,0)
	#matching data
	match expected_data_type:
		"INT":
			if str_format == "NONE":
				get_parent().text = str(int(val))+added_end_text
			elif str_format == "CURRENCY":
				get_parent().text = Global.CurrencyToString(int(val))+added_end_text
		"FLOAT":
			get_parent().text = str(float(val))+added_end_text
			
		_:
			get_parent().text = val+added_end_text
	

func GetVal(passed_data,cur_index):
	if _cur_list.size()-1==cur_index:
		return passed_data[_cur_list[cur_index]]
	else:
		return GetVal(passed_data[_cur_list[cur_index]],cur_index+1)
