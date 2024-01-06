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


var game_scene : Node2D
var levels : Node2D
var player : CharacterBody2D
var scene_dict : Dictionary
var game_clock : Label
var tick_speed : int
var paused : bool
var item_picked : Dictionary  # {node_id, interactable, texture}
var container_open : Inventory


var active_scene : Node2D
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	print(FuzzyFactors.keys())
	
	# DB HANDLING
	db.path = db_name
	#----------------#
	
	# SCENE HANDLING
	for scene_key in scene_path_dict:
		var scene_path = scene_path_dict[scene_key]
		scene_dict[scene_key] = load(scene_path).instantiate()


func _process(delta):
	if item_picked:
		var texture = item_picked["interactable"].interact_icon
		var vec = get_global_mouse_position() # - item.position
		print(vec)
		## vec = vec.normalized() * delta * 1
		texture.set_global_position(vec)
		## item.position = vec
	if Input.is_action_just_pressed("inventory"):
		if player.inventory.opened:
			if container_open:
				container_open.close()
			else:
				player.inventory.close()
		elif Input.is_action_just_pressed("inventory"):
			player.open_inventory()
	elif not get_tree().paused and Input.is_action_just_pressed("interact"):
		player.execute_interaction()


func change_scene(scene_key : SceneList, player_pos : Vector2 = Vector2.ZERO):
	var destination_scene = scene_dict[scene_key]
	if not destination_scene:
		scene_dict[scene_key] = load(scene_path_dict[scene_key]).instantiate()
		destination_scene = scene_dict[scene_key]
	if destination_scene.get_parent() != levels:
		levels.add_child(destination_scene)
	if active_scene:
		active_scene.set_process(false)
		active_scene.visible = false
		# active_scene.queue_free()
		# levels.remove_child(active_scene)
	player.position = player_pos
	active_scene = destination_scene
	active_scene.set_process(true)
	active_scene.visible = true
	pass


func close_container(container_inventory : Inventory):
	player.inventory.position = Vector2(player.inventory.position.x, player.inventory.position.y - 60)
	# container_inventory.close()
	container_open = null
	player.inventory.has_close_button = true
	player.close_inventory()


func open_container(container_inventory : Inventory):  # TODO: Should contain all of the items that the container should have as an argument
	container_open = container_inventory
	player.inventory.has_close_button = false
	player.open_inventory()
	container_inventory.open()
	var global_pos = player.inventory.get_global_position()
	container_inventory.set_global_position(Vector2(global_pos.x + 5, global_pos.y - 40))
	player.inventory.position = Vector2(player.inventory.position.x, player.inventory.position.y + 60)


func pick_or_place(item : Dictionary):
	if item_picked != {}:  # Placing an item in a container
		item["container"].insert_at(item_picked, item["node_id"])
		item_picked["interactable"].interact_icon.queue_free()
		item_picked = {}
		return false
	elif item.has("interactable"):  # Picking an item from a container
		item_picked = item
		if Input.get_action_strength("sprint"):  # Quick move (Shift)
			if item["container"] == player.inventory:
				if container_open:
					container_open.insert_item(item["interactable"])
					item_picked = {}
			else:
				player.inventory.insert_item(item["interactable"])
				item_picked = {}
		return true
	else:
		return false


func pause_game(do_pause : bool = true):
	paused = do_pause
	get_tree().paused = do_pause


func readFromDB(table, row_clause='*', conditional='1=1'):
	var query = 'select ' + row_clause + ' from ' + table + ' where ' + conditional + ';'
	db.open_db()
	db.query(query)
	return db.query_result


func spawn_collectibles(template : Sprite2D, pos : Vector2, count : int = 1, pos_offset : Vector2 = Vector2(20, 20)):
	for i in count:
		var instance = template.duplicate()
		instance.process_mode = Node.PROCESS_MODE_INHERIT
		instance.visible = true
		instance.position = Vector2(pos.x + randf_range(-pos_offset.x,pos_offset.x), pos.y + randf_range(-pos_offset.y,pos_offset.y))
		active_scene.add_child(instance)

