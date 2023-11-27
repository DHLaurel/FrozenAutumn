extends Node


@export var portal_destination : GlobalNode.SceneList

@export var locked : bool = false
@export var position_destination : Vector2 = Vector2.ZERO

@onready var static_body = $StaticBody2D
@onready var interact_area = $InteractArea
@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")
@onready var is_open = false


func _ready():
	if locked:
		interact_area.interact_label = "Locked Door"
	else:
		interact_area.interact_label = "Door"

func open_door():
	print("opening door")
	state_machine.travel("door_open")  # Ends with door_opened
	
func close_door():
	print("closing door")
	state_machine.travel("door_close")  # Ends with door_opened
	
func interact():
	if not locked:
		if not is_open:
			is_open = true
			open_door()
		else:
			is_open = false
			close_door()
	else:
		print("The door is locked.")

func _on_interact_area_interaction_executed():
	interact()


func _on_animation_tree_animation_finished(anim_name):
	print("anim_name")
	if anim_name == "door_opened":
		static_body.process_mode = Node.PROCESS_MODE_DISABLED
		# get_tree().change_scene_to_file(portal_destination)
		GlobalNode.change_scene(portal_destination, position_destination)
		
		print("Got here")
		
	if anim_name == "door_closed":
		static_body.process_mode = Node.PROCESS_MODE_ALWAYS
