extends Control

@onready var currency_anim = preload("res://scenes/components/currency_animation.tscn")
@onready var chest_anim = preload("res://scenes/components/chest_animation.tscn")

func _ready() -> void:
	GlobalSignals.ShowCurrencyAnimation.connect(ShowCurrencyAnimation)
	GlobalSignals.ShowChestAnimation.connect(ShowChestAnimation)
	
func ShowCurrencyAnimation(from_glob_pos:Vector2,currency_type:String,value:int):
	for x in value:
		var c = currency_anim.instantiate()
		c.global_position = from_glob_pos
		add_child(c)
		c.StartAnimation(currency_type)

func ShowChestAnimation(from_glob_pos:Vector2,chest_type:String):
	var c = chest_anim.instantiate()
	c.global_position = from_glob_pos
	add_child(c)
	c.StartAnimation(chest_type)
