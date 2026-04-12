extends Control
class_name RelicUpgradeItemClass

var cur_relic_id := ""

func _ready() -> void:
	GlobalSignals.OnRelicUpgradeSelected.connect(OnRelicSelected)
	GlobalBtn.AddBtnPress(self)
	GlobalBtn.BtnPress.connect(OnBtnPress)
	SetAsUnSelected()

func OnBtnPress(control_node:Control):
	if control_node != self:
		return
	GlobalSignals.OnRelicUpgradeSelected.emit(self)
	
func OnRelicSelected(relic_item:RelicUpgradeItemClass):
	if relic_item == self:
		SetAsSelected()
	else:
		SetAsUnSelected()
		
func InitOwnedItem(relic_id:String)->void:
	cur_relic_id = relic_id
	var owned_relic_data = GlobalRelicDb.GetOwnedRelicSaveData(relic_id)
	var relic_data = GlobalRelicDb.GetRelicDataByID(relic_id)
	var relic_color = GlobalColor.GetRelicRankColor(owned_relic_data.rank)
	$VBoxContainer/IconBG.panel_color = relic_color
	$VBoxContainer/IconBG.icon = GlobalRelicDb.GetRelicIcon(relic_data.icon)
	$VBoxContainer/IconBG/dupe_amount.text = "x"+str(owned_relic_data.dupes).pad_decimals(0)
	$VBoxContainer/relic_name.text = relic_data.title
	$VBoxContainer/relic_name.hash_tag_color = relic_color

func SetAsSelected():
	$is_selected.visible = true
	
func SetAsUnSelected():
	$is_selected.visible = false
