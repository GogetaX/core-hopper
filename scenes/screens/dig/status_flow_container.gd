extends HFlowContainer

@onready var status_label = preload("res://scenes/components/status_label.tscn")

func _ready() -> void:
	GlobalSignals.DataSaved.connect(OnSaved)
	SyncStatus()
	
func OnSaved():
	SyncStatus()
	
func SyncStatus():
	#Remove old status labels
	for x in get_children():
		x.queue_free()
	CheckForDiggingInactive()

func CheckForDiggingInactive():
	var cur_color = "BLUE"
	var is_active = false
	for x in GlobalSave.save_data.lanes:
		if x.bot_uid != -1:
			if x.auto_dig_unlocked:
				is_active = true
				break
				
	if !is_active:
		var s : StatusLabelClass = status_label.instantiate()
		s.panel_color = cur_color
		s.status_text = "DIGGING INACTIVE"
		add_child(s)
