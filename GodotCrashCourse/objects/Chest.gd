extends Sprite2D

@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")
@onready var has_interacted = false

func play_animation():
	state_machine.travel("chest_open")
	
	
func interact():
	if not has_interacted:
		has_interacted = true
		play_animation()
		

func _on_interact_area_interaction_executed():
	interact()

