@tool
extends Control
class_name CurrencyIconClass

@export_enum("CRYSTAL_BIG_ANIMATED","COIN_SMALL","ENERGY_SMALL","ENERGY_SMALL_ANIMATED","CRYSTAL_SMALL") var icon_type := "CRYSTAL_BIG_ANIMATED":
	set(value):
		icon_type = value
		if is_node_ready():
			_ready()
	get:
		return icon_type

func _ready() -> void:
	HideAllAndStopAnimation()
	ShowOnly()
	
func ShowOnly():
	$Energy_Small_Animated/AnimationPlayer.stop()
	match icon_type:
		"CRYSTAL_BIG_ANIMATED":
			$Crystal_Big_Animated.visible = true
		"CRYSTAL_SMALL":
			$Crystal_Small.visible = true
		"COIN_SMALL":
			$Coin_Small.visible = true
		"ENERGY_SMALL":
			$Energy_Small.visible = true
		"ENERGY_SMALL_ANIMATED":
			$Energy_Small.visible = true
			$Energy_Small_Animated/AnimationPlayer.play("in_out")

func HideAllAndStopAnimation():
	for x in get_children():
		x.visible = false

func FindVisible():
	for x in get_children():
		if x.visible:
			return x
	return null
	
func AnimateCurrencyIn():
	var cur_currency = FindVisible()
	if cur_currency:
		var t = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		t.tween_property(cur_currency,"scale",Vector2(1.15,1.15),0.1)
		t.tween_property(cur_currency,"scale",Vector2(1.0,1.0),0.1)
