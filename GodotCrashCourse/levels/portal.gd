extends Node2D


@export_file var dest_scene = 

@onready var entered = false

func _process(delta):
	if entered == true:
		get_tree().change_scene_to_file(dest_scene)


func _on_interact_area_body_entered(body):
	entered = true


func _on_interact_area_body_exited(body):
	entered = false
