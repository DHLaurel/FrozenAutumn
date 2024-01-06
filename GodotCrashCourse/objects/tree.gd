extends Sprite2D

@export var max_health : float = 100
@export var wood_drop_range : Vector2i = Vector2i(1, 5)

@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")
@onready var wood_template = $Wood

@onready var _current_health : float = max_health

var _is_just_stump = false

func _ready():
	wood_template.visible = false
	wood_template.process_mode = Node.PROCESS_MODE_DISABLED

func update_health(increment_amount : float):
	_current_health += increment_amount
	if not _is_just_stump and _current_health <= 0:
		break_tree()
		
	if _is_just_stump and _current_health <= -(max_health):
		state_machine.travel("stump_break")


func break_tree():
	region_enabled = true  # Makes Tree Sprite invisible
	_is_just_stump = true
	spawn_wood()


func spawn_wood():
	var wood_count = randi_range(wood_drop_range.x, wood_drop_range.y)  # TODO: Make this random between 1 and max wood, potential for fuzzy variables...
	GlobalNode.spawn_collectibles(wood_template, position, wood_count)


func _on_interact_area_attack_executed():
	state_machine.travel("tree_chop")
	update_health(-20)
