extends Sprite2D

@export var max_health : float = 100

@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")
@onready var _current_health : float = max_health

var _is_just_stump = false

func update_health(increment_amount : float):
	_current_health += increment_amount
	if _current_health <= 0:
		region_enabled = true
		_is_just_stump = true
		
	if _is_just_stump and _current_health <= -(max_health):
		state_machine.travel("stump_break")

func _on_interact_area_attack_executed():
	state_machine.travel("tree_chop")
	update_health(-20)
