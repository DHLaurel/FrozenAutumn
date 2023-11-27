extends CharacterBody2D

enum COW_STATE { IDLE = 0, WALK = 1, ATTACKED = 2, FLEE = 3}

@export var move_speed : float = 15
@export var idle_time : float = 5
@export var walk_time : float = 2
@export var bark_frequency : float = 0.3
@export var max_health : float = 100

@onready var audio_player = $AudioStreamPlayer2D
@onready var bark_text = $BarkText
@onready var interact_area = $InteractArea
@onready var health_bar = $HealthBar
@onready var sprite = $Sprite2D
@onready var timer = $Timer
@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")

@onready var _current_health : float = max_health

var move_direction : Vector2 = Vector2.ZERO
var current_state : COW_STATE = COW_STATE.IDLE

var _interacting : bool = false
var _debug = OS.is_debug_build()

func _ready():
	random_state()
	bark_randomly()


func _physics_process(delta):
	if current_state in [COW_STATE.WALK, COW_STATE.FLEE]:
		velocity = move_direction * randf_range(move_speed / 2, move_speed)
		if current_state == COW_STATE.FLEE:
			print_debug("fleeing with velocity: ", velocity)
			velocity = velocity * 3
		move_and_collide(velocity * delta)


func select_new_direction():
	move_direction = Vector2(
		randi_range(-1, 1),
		randi_range(-1, 1)
	)
	if move_direction == Vector2.ZERO:
		# Try one more time to avoid walking in place, otherwise give up
		move_direction = Vector2(
		randi_range(-1, 1),
		randi_range(-1, 1)
	)
	
	if move_direction.x < 0:
		sprite.flip_h = true
	else:
		sprite.flip_h = false
	
	
func change_state(state : COW_STATE):
	match state:
		COW_STATE.WALK:
			state_machine.travel("walk_right")
			current_state = COW_STATE.WALK
			select_new_direction()
			timer.start(walk_time + randi_range(-1, 1))

		COW_STATE.IDLE:
			state_machine.travel("idle_right")
			current_state = COW_STATE.IDLE
			timer.start(idle_time + randi_range(-1, 1))
			
		COW_STATE.ATTACKED:
			state_machine.travel("under_attack")
			current_state = COW_STATE.ATTACKED
		
		COW_STATE.FLEE:
			state_machine.travel("walk_right")
			current_state = COW_STATE.FLEE
			select_new_direction()
			timer.start(idle_time + randi_range(-1, 1))
			
			


var _rand_state_list = [COW_STATE.IDLE, COW_STATE.WALK]
func random_state():
	var state = _rand_state_list[randi() % _rand_state_list.size()]
	change_state(state)

func update_health(increment_amount : float):
	_current_health += increment_amount
	print("cow current health: ", _current_health)
	health_bar.value = (_current_health / max_health) * 100.0
	print("updated cow health perc to ", health_bar.value)

func _on_timer_timeout():
	random_state()


func _on_interact_area_interaction_executed():
	interact_area.interact_label = interact_area.interact_value
	
	
	#BARK TEXT
@export var _bark_list : Array[String] = ["Bark!",]
func bark(message: String = "Bark!"):
	var tree = get_tree()
	if tree:
		if not _interacting:
			if _debug: print("barking: ", message)
			for i in range(len(message)+1):
				bark_text.text = message.substr(0, i)
				await(tree.create_timer(0.5).timeout)
				
		await(tree.create_timer((1 / bark_frequency) * 2.0).timeout)
		bark_text.text = ""
	
func choose_bark_message():
	return _bark_list[randi() % _bark_list.size()]
	
	
func bark_randomly():
	var tree = get_tree()
	if tree:
		var bark_message = choose_bark_message()
		if _debug: print(name, "Barking randomly")
		await(bark(bark_message))
		var bark_delay = randf_range((1 / bark_frequency) * 0.25, (1 / bark_frequency) * 2.0) # randomly pick around the frequency to make the barks seem less predictable
		if _debug: print(name, "bark_delay_start")
		await(get_tree().create_timer(bark_delay).timeout)
		if _debug: print(name, "bark_delay_stop, bark_delay: ", bark_delay)
		bark_randomly()


func _on_interact_area_attack_executed():
	print("attacking cow :(")
	update_health(-15)
	if current_state not in [COW_STATE.FLEE, COW_STATE.ATTACKED]:
		change_state(COW_STATE.ATTACKED)
	else:
		change_state(COW_STATE.FLEE)
	# audio_player.play()
	if _current_health <= 0.0:
		queue_free()
