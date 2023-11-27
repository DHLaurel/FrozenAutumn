extends Node

class ItemSlot:
	var item_texture : Texture2D
	var stack_count : Label

@export_node_path var inventory_panel_path
@export_node_path var item_slot_template_path
@export_node_path var item_template_path
@export_node_path var stack_count_template_path

@export var max_slots = Vector2i.ZERO
@export var gap_adjustment = Vector2(8, 8)

@onready var inventory_panel : NinePatchRect = get_node(inventory_panel_path)
@onready var item_slot_template : TextureButton = get_node(item_slot_template_path)
@onready var item_template : TextureRect = get_node(item_template_path)
@onready var stack_count_template : Label = get_node(stack_count_template_path)

@onready var initial_slot_position = item_slot_template.position

var items : Array[CollectibleResource]
var _item_nodes : Dictionary  # Texture2Ds that we'll 


func _ready():
	var item_slot
	var item
	var stack_count
	var pos = initial_slot_position
	
	for i in range(max_slots.y):
		for j in range(max_slots.x):
			item_slot = item_slot_template.duplicate()
			item = item_template.duplicate()
			stack_count = stack_count_template.duplicate()
			inventory_panel.add_child(item_slot)
			item_slot.add_child(item)
			item_slot.add_child(stack_count)
			item_slot.position = pos
			_item_nodes[Vector2i(i,j)] = {"item": item, "stack_count" : stack_count}
			pos.x += gap_adjustment.x
		pos.y += gap_adjustment.y
		pos.x = initial_slot_position.x
	item_slot_template.queue_free()
	item_template.queue_free()


func append(item):
	if items.size() < _item_nodes.size():
		items.append(item)
		return true
	else:
		return false


func insert_item(item : CollectibleResource):
	var insert_success = true
	if item.stackable:
		var existing_item = items.find(item)
		if existing_item != -1:
			if (item.stack_count + existing_item.stack_count) < item.max_stack:
				existing_item.stack_count += item.stack_count
			else:
				existing_item.stack_count = existing_item.max_stack
				item.stack_count = item.max_stack - existing_item.stack_count
		else:
			insert_success = append(item)
	else:
		insert_success = append(item)
		
	if insert_success:
		update_inventory_canvas()
	return insert_success


func update_inventory_canvas():
	var i : int = 0
	var dict_pos : Vector2i = Vector2.ZERO
	for item in items:
		dict_pos = Vector2i(i / max_slots.y, i % max_slots.y)
		_item_nodes[dict_pos]["item"].texture = item.icon
		if item.stackable:
			_item_nodes[dict_pos]["stack_count"].text = "x" + str(item.stack_count)
		else:
			_item_nodes[dict_pos]["stack_count"].text = ""
		i += 1
		# TODO: Add a delete function
	pass
	# clear()
	# for item in stackable_item_dict:
	#	var count = stackable_item_dict[item]
	#	var counter = "x" + str(count)
	#	add_item(counter, item.icon)
