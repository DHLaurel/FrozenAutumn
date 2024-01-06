extends CharacterBody2D

@export var max_health : float = 25.0
@export var movement_speed : float = 100.0
@export var starting_direction : Vector2 = Vector2(0, 1)
@export var sprint_multiplier : float = 2.0

# parameters/Idle/blend_position

@onready var health_bar = $HealthBar
@onready var inventory = $InventoryContainer
@onready var interaction_direction = $InteractionComponents/InteractionDirection
@onready var interact_label = $InteractionComponents/InteractLabel
@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")

@onready var _current_health : float = max_health

var _is_attacking : bool = false


func _ready():
	update_animation_parameters(starting_direction, _is_attacking)



#=======================================================#
# Physics Methods
#=======================================================#

func _physics_process(_delta):
	var input_direction = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up")
	)
	
	if Input.is_action_pressed("attack"):
		_is_attacking = true
	else:
		_is_attacking = false
		
	update_animation_parameters(input_direction, _is_attacking)
	
	if input_direction != Vector2.ZERO:
		var angle = input_direction.angle()
		var modifier = (3 * PI / 2) # +270
		var final_angle = angle + modifier# rad_to_deg(input_direction.angle()) + modifier
		interaction_direction.rotation = final_angle
		
	var normal_direction = input_direction.normalized()
	
	# Update velocity
	if (Input.get_action_strength("sprint")):
		velocity = normal_direction * (movement_speed * sprint_multiplier)
	else:
		velocity = normal_direction * movement_speed
	
	# Move and Slide function uses velocity of character body to move character on map
	# move_and_collide(velocity * _delta)
	move_and_slide()
	
	# Handle interactions
	if not _is_attacking:
		pass
		# if Input.is_action_just_pressed("interact"):  # Don't interact unless we're not attacking - can't do both!
			# execute_interaction()


func update_animation_parameters(move_input : Vector2, attack_down : bool):
	if (move_input  != Vector2.ZERO):
		animation_tree.set("parameters/Idle/blend_position", move_input)
		animation_tree.set("parameters/Walk/blend_position", move_input)
		animation_tree.set("parameters/AxeSwing/blend_position", move_input)
	
	if(velocity != Vector2.ZERO):
		state_machine.travel("Walk")
	#else:
	elif not attack_down:
		state_machine.travel("Idle")
	if attack_down:
		state_machine.travel("AxeSwing")
	# else:
	#	state_machine.travel("Idle")


#=======================================================#
# Player Methods
#=======================================================#

func update_health(increment_amount : float):
	_current_health += increment_amount
	health_bar.value = (_current_health / max_health) * 100.0
	


#=======================================================#
# UI Methods
#=======================================================#


func open_inventory():
	inventory.open()
	GlobalNode.pause_game(true)
	# inventory.process_mode = Node.PROCESS_MODE_WHEN_PAUSED


func close_inventory():
	inventory.close()
	GlobalNode.pause_game(false)
	# inventory.process_mode = Node.PROCESS_MODE_


func _on_inventory_container_inventory_closed():
	GlobalNode.pause_game(false)
	# close_inventory()



#=======================================================#
# Interaction Methods
#=======================================================#

func give_item(item : Interact_Area):
	# inventory.add_item(item.interact_value, item.interact_icon.get_texture())
	inventory.insert_item(item)
	pass


var _interact_list = []
func _on_interaction_area_area_entered(area):
	if area.interact_type in [Interact_Area.INTERACT_TYPE.COLLECTIBLE ]:
		give_item(area)
	else:
		_interact_list.insert(0, area)
		update_interactions()


func _on_interaction_area_area_exited(area):
	_interact_list.erase(area)
	update_interactions()


func update_interactions():
	if _interact_list:
		var top_interaction = _interact_list[0]
		interact_label.text = top_interaction.interact_label
		
	else:
		interact_label.text = ""


func execute_interaction():
	if _interact_list:
		var top_interaction = _interact_list[0]
		top_interaction.execute_interaction()
		#match top_interaction.interact_type:
		#	Interact_Area.INTERACT_TYPE.CONTAINER_OPEN:
		#		print(top_interaction.interact_value)


var _attack_list : Array[Area2D] = []
func _on_attack_area_area_entered(area):
	_attack_list.append(area)


func _on_attack_area_area_exited(area):
	_attack_list.erase(area)


func execute_attack():
	if _attack_list:
		for attack_victim in _attack_list:
			attack_victim.execute_attack()
