extends Label

func _ready() -> void:
	GlobalSignals.DataSaved.connect(SyncData)
	SyncData()
	
func SyncData():
	var count :int = 0
	for x in GlobalSave.save_data.lanes:
		if !x.is_empty():
			if x.auto_dig_unlocked && x.bot_uid != -1:
				count += 1
	text = str(count)+" bot(s) online"
	
