extends Control

@onready var relic_item = preload("res://scenes/screens/progress/relic_item.tscn")
@onready var hashtag = preload("res://scenes/screens/progress/progress_hash_tag.tscn")

var cur_popup_data = {}


func _ready() -> void:
	SyncInvRelics()
	
func InitCurPopupData(data):
	cur_popup_data = data
	
func SyncInvRelics():
	var owned_relics = GlobalRelicDb.GetAllOwnedRelics()
	#Remove old Relics
	for x in $SmartPanel/VBoxContainer/Scroll/HFlow.get_children():
		x.queue_free()
		
		
	if owned_relics.is_empty():
		var h = hashtag.instantiate() as HashtagClass
		h.hash_tag_color = "GOLD"
		h.no_bg = true
		h.text = "NO AVAILABLE RELICS"
		h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		$SmartPanel/VBoxContainer/Scroll/HFlow.add_child(h)
	else:
		for x in owned_relics:
			var r = relic_item.instantiate() as RelicItemClass
			$SmartPanel/VBoxContainer/Scroll/HFlow.add_child(r)
			r.InitItem(x,cur_popup_data)
			r.OnEquip.connect(OnRelicEquip)
	
	
func OnRelicEquip(_is_equiped):
	SyncInvRelics()
	GlobalSave.SyncSave()
	_on_close_popup_btn_pressed()
	GlobalSignals.OnRelicSynced.emit()

func _on_close_popup_btn_pressed() -> void:
	GlobalSignals.CloseCurPopup.emit()


func _on_open_relic_inv_btn_on_press() -> void:
	GlobalSignals.ShowPopup.emit("UPGRADE_RELIC_POPUP",{})
