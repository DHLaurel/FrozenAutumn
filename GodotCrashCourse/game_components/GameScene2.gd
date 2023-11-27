extends Node2D

var game_paused = false

func _ready():
	GlobalNode.levels = $Levels
	GlobalNode.player = $PlayerCat
	GlobalNode.game_clock = $ClockCanvas/GameClock
	GlobalNode.change_scene(GlobalNode.SceneList.OVERWORLD, GlobalNode.player.position)
	
func _process(_delta):
	pass
	#if Input.is_action_just_pressed("pause"):
		#GlobalNode.player.open_inventory()
