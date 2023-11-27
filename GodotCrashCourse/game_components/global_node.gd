extends Node2D

#--DB Access
const db_name = "res://game_components/db/dialogue.db"
@onready var db = SQLite.new()


#--SCENE HANDLING
enum SceneList { 
	OVERWORLD = 0, 
	INDOOR_HOUSE_1 = 1
}

@onready var scene_path_dict : Dictionary = { 
	SceneList.OVERWORLD  : "res://levels/game_level.tscn", 
	SceneList.INDOOR_HOUSE_1 : "res://levels/indoor_level.tscn"
}

#--FUZZY HANDLING
enum FuzzyFactors {
	GAMETIME = 0,
	FORTUNE = 1
}

@onready var fuzzy_factors : Dictionary = {
	FuzzyFactors.GAMETIME : Vector2i(0, 0),
	FuzzyFactors.FORTUNE : 50
}

enum TimeConsts {
	MIN_TIME = 0,
	MAX_TIME = 1439
}

var levels : Node2D
var player : CharacterBody2D
var scene_dict : Dictionary
var game_clock : Label


var active_scene : Node2D
func _ready():
	print(FuzzyFactors.keys())
	
	# DB HANDLING
	db.path = db_name
	#----------------#
	
	# SCENE HANDLING
	for scene_key in scene_path_dict:
		var scene_path = scene_path_dict[scene_key]
		scene_dict[scene_key] = load(scene_path).instantiate()
	

func change_scene(scene_key : SceneList, player_pos : Vector2 = Vector2.ZERO):
	var destination_scene = scene_dict[scene_key]
	if not destination_scene:
		scene_dict[scene_key] = load(scene_path_dict[scene_key]).instantiate()
		destination_scene = scene_dict[scene_key]
	levels.add_child(destination_scene)
	if active_scene:
		active_scene.set_process(false)
		active_scene.queue_free()
		levels.remove_child(active_scene)
	player.position = player_pos
	active_scene = destination_scene
	pass
	

func readFromDB(table, row_clause='*', conditional='1=1'):
	var query = 'select ' + row_clause + ' from ' + table + ' where ' + conditional + ';'
	db.open_db()
	db.query(query)
	return db.query_result
