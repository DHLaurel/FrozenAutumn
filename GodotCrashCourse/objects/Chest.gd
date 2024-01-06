extends Sprite2D

@export var item_drop_range : Vector2i = Vector2i(1, 4)

@onready var animation_tree = $AnimationTree
@onready var inventory = $InventoryContainer
@onready var state_machine = animation_tree.get("parameters/playback")
@onready var stone_template = $StoneTemplate
@onready var has_opened = false


func _ready():
	stone_template.visible = false
	stone_template.process_mode = Node.PROCESS_MODE_DISABLED


func play_animation():
	state_machine.travel("chest_open")


func interact():
	play_animation()


func spawn_treasure():
	for i in 10:
		var stone_tmp = stone_template.duplicate()
		stone_tmp.get_child(0).collectible_count = 30
		inventory.insert_item(stone_tmp.get_child(0))


func open_chest():  # Called in AnimationPlayer
	if not has_opened:
		spawn_treasure()
		has_opened = true
	GlobalNode.open_container(inventory)
	var count = randi_range(item_drop_range.x, item_drop_range.y)
	# GlobalNode.spawn_collectibles(stone_template, position, count)


func _on_interact_area_interaction_executed():
	interact()


func _on_inventory_container_inventory_closed():
	state_machine.travel("chest_close")
	GlobalNode.close_container(inventory)
