extends VBoxContainer

@onready var notif_item = preload("res://scenes/components/notification_item.tscn")

func _ready() -> void:
	GlobalSignals.AddNotification.connect(OnAddNotifData)
	_RemoveOldNotif()
	
func _RemoveOldNotif():
	for x in get_children():
		x.queue_free()

func OnAddNotifData(notif_data:Dictionary)->void:
	var n = notif_item.instantiate() as NotifItemClass
	position.y = Global.top_bar_y_pos
	add_child(n)
	move_child(n,0)
	match notif_data.type:
		"TEXT":
			n.InitTextNotif(notif_data.description,notif_data.color)
