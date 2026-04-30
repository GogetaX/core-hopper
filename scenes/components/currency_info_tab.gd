@tool
extends Control
class_name CurrencyTabClass

@export_enum("COINS","CRYSTALS","DUST","ENERGY") var currency_type := "COINS":
	set(value):
		currency_type = value
		if is_node_ready():
			_ready()
	get:
		return currency_type
		
@export var default_selected := false
@export var tab_id = "where_to_find_tab"
		
func _ready() -> void:
	match currency_type:
		"COINS":
			$SmartPanel/VList/CurrencyIcon.icon_type = "COIN_SMALL"
			$SmartPanel/VList/ProgressHashTag.text = "COINS"
		"CRYSTALS":
			$SmartPanel/VList/CurrencyIcon.icon_type = "CRYSTAL_SMALL"
			$SmartPanel/VList/ProgressHashTag.text = "CRYSTALS"
		"DUST":
			$SmartPanel/VList/CurrencyIcon.icon_type = "DUST_SMALL"
			$SmartPanel/VList/ProgressHashTag.text = "DUST"
		"ENERGY":
			$SmartPanel/VList/CurrencyIcon.icon_type = "ENERGY_SMALL"
			$SmartPanel/VList/ProgressHashTag.text = "ENERGY"
		_:
			print_debug("Unknown Currency: ",currency_type)
	if !Engine.is_editor_hint():
		GlobalBtn.AddBtnPress(self)
		GlobalBtn.BtnPress.connect(OnBtnPress)
		GlobalSignals.OnCurrencyTabPressed.connect(OnTabPressed)
		if default_selected:
			SetSelected()
		
func OnTabPressed(btn_node: CurrencyTabClass):
	if btn_node.tab_id != tab_id:
		return
	if btn_node == self:
		SetSelected()
	else:
		SetUnSelected()
		
func OnBtnPress(btn_control:Control):
	if btn_control != self:
		return
	GlobalSignals.OnCurrencyTabPressed.emit(self)
	
func SetSelected():
	GlobalBtn.AnimateBtnPressed($SmartPanel)
	$SmartPanel.panel_type = "BORDER_AND_INSIDE"
	
func SetUnSelected():
	$SmartPanel.panel_type = "INSIDE_ONLY"
