extends Node

func _ready() -> void:
	GlobalSignals.DataSaved.connect(SyncData)
	SyncData()
	
func SyncData():
	var owned_relics = GlobalRelicDb.GetAllOwnedRelics()
	get_parent().hash_tag_text = str(owned_relics.size()).pad_decimals(0)+" OWNED"
