class_name Interact_Area extends Area2D

signal interaction_executed
signal attack_executed

enum INTERACT_TYPE { 
					NONE = 0,
					TALK = 1, 
					PRINT = 2,
					CONTAINER_OPEN = 3,
					PORTAL = 4,
					COLLECTIBLE = 5,
					BREAKABLE = 6
					}


@export var interact_label = "no_label"
@export var interact_type = INTERACT_TYPE.NONE
@export var interact_value = "no_value"
@export var interact_icon = Sprite2D.new()
@export var collectible_resource : CollectibleResource
@export var collectible_count : int = 0

@export_file var interact_file = ""


func execute_interaction():
	print('executing interaction')
	emit_signal("interaction_executed")


func execute_attack():
	print('executing attack')
	emit_signal("attack_executed")
