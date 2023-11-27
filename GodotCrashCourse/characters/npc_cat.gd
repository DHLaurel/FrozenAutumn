extends CharacterBody2D

@export var movement_speed : float = 100.0
@export var starting_direction : Vector2 = Vector2(0, 1)
@export var speech_speed : float = 12.5
@export var sprint_multiplier : float = 2.0
@export var speech_sprint_multiplier : float = 2.0
@export var speech_timeout : float = 3.0
@export var bark_frequency : float = 4.0
@export var npc_name : String = "NPC Cat"
@export var saying : String = "Kwhat do you kwant?..."


# parameters/Idle/blend_position

@onready var dialogue_text = $InteractionComponents/DialogueText
@onready var bark_text = $InteractionComponents/BarkText
@onready var interact_area = $InteractArea
@onready var timer = $Timer
@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")

@onready var dialogue_handler = $DialogueHandler
# @onready var _dialogue_handler_script = load("res://game_components/cs_scripts/DBDialogueHandler.cs")
# @onready var dialogue_handler = _dialogue_handler_script.new()

@onready var _debug = OS.is_debug_build()

func _ready():
	interact_area.interact_label = npc_name
	speech_speed = 1.0 / speech_speed
	update_animation_parameters(starting_direction)
	
	dialogue_handler.init(npc_name)
	bark_randomly()


func _physics_process(_delta):	
	if Input.is_action_just_pressed("interact"):
		speech_speed = speech_speed / speech_sprint_multiplier
	elif Input.is_action_just_released("interact"):
		speech_speed = speech_speed * speech_sprint_multiplier
	# Move and Slide function uses velocity of character body to move character on map
	# move_and_slide()


func update_animation_parameters(move_input : Vector2):
	if (move_input  != Vector2.ZERO):
		animation_tree.set("parameters/Idle/blend_position", move_input)
		animation_tree.set("parameters/Walk/blend_position", move_input)
	
	if(velocity != Vector2.ZERO):
		state_machine.travel("Walk")
	else:
		state_machine.travel("Idle")


func speak(message : String = saying):
	print("speaking: ", message)
	for i in range(len(message)+1):
		dialogue_text.text = message.substr(0, i)
		await(get_tree().create_timer(speech_speed).timeout)
			
	await(get_tree().create_timer(speech_timeout).timeout)
	dialogue_text.text = ""
	
var _yelling = false
func yell(message):
	if not _yelling:
		_yelling = true
		print("yelling: ", message)
		dialogue_text.text = message
		await(get_tree().create_timer(speech_timeout).timeout)
		dialogue_text.text = ""
		_yelling = false
	
#========================================#
#	Bark Functions						 #
#========================================#

@export var _bark_list : Array[String] = ["Bark!",]
func bark(message: String = saying):
	var tree = get_tree()
	if tree:
		if not _interacting:
			if _debug: print("barking: ", message)
			for i in range(len(message)+1):
				bark_text.text = message.substr(0, i)
				await(get_tree().create_timer(speech_speed).timeout)
				
		await(get_tree().create_timer((1 / bark_frequency) * 2.0).timeout)
		bark_text.text = ""
	

func choose_bark_message():
	# dialogue_handler.printNTimes(4)
	# var bark_message = dialogue_handler.get_catchphrase()
	var bark_message = dialogue_handler.get_fuzzy_catchphrase()
	# return _bark_list[randi() % _bark_list.size()]
	return bark_message
	
	
func bark_randomly():
	print(name, " barking randomly")
	var tree = get_tree()
	if tree:
		var bark_message = choose_bark_message()
		await(bark(bark_message))
		var bark_delay = randf_range((1 / bark_frequency) * 0.25, (1 / bark_frequency) * 2.0) # randomly pick around the frequency to make the barks seem less predictable
		if _debug: print("bark_delay_start")
		await(tree.create_timer(bark_delay).timeout)
		if _debug: print("bark_delay_stop, bark_delay: ", bark_delay)
		bark_randomly()
	
	
#========================================#
#	Interaction Functions				 #
#========================================#

var _interacting = false

func interact():
	print("interacting: " + str(_interacting))
	if not _interacting:
		_interacting = true
		await(speak())
		_interacting = false
		

func attack():
	print("attacking: ", name)
	_interacting = true
	await(yell("HEY! Cut it out!"))
	_interacting = false
	

func _on_interact_area_interaction_executed():
	interact()

func _on_interact_area_attack_executed():
	attack()

func _on_interaction_area_area_entered(_area):
	pass # Replace with function body.


func _on_interaction_area_area_exited(_area):
	pass


func _on_timer_timeout():
	pass



