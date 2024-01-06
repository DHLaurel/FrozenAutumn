class_name Inventory extends Node

signal inventory_closed

class ItemSlot:
	var id : Vector2i
	var interactable : Interact_Area
	var texture : Texture2D


@export_node_path var inventory_panel_path
@export_node_path var item_slot_template_path
@export_node_path var item_texture_template_path
@export_node_path var stack_count_template_path

@export var has_hotbar = false
@export var has_close_button = true
@export var max_slots = Vector2i.ZERO
@export var gap_adjustment = Vector2(8, 8)

@onready var inventory_panel : NinePatchRect = get_node(inventory_panel_path)
@onready var item_slot_template : TextureButton = get_node(item_slot_template_path)
@onready var item_texture_template : TextureRect = get_node(item_texture_template_path)
@onready var stack_count_template : Label = get_node(stack_count_template_path)

@onready var initial_slot_position = item_slot_template.position
@onready var opened : bool = false

var items : Dictionary  # node_vector_id : interactable
var _canvas_nodes : Dictionary  # Texture2Ds that we'll 
var _node_slot_lookup : Dictionary
var _free_spaces : Array[Vector2i]  # To keep track of empty slots for fast retrieval



func _ready():
	var item_button
	var item_texture
	var stack_count_label
	var pos = initial_slot_position
	
	for i in range(max_slots.y):
		for j in range(max_slots.x):
			var node_index = Vector2i(i,j)
			item_button = item_slot_template.duplicate()
			item_texture = item_texture_template.duplicate()
			stack_count_label = stack_count_template.duplicate()
			inventory_panel.add_child(item_button)
			item_button.add_child(item_texture)
			item_button.add_child(stack_count_label)
			item_button.position = pos
			_canvas_nodes[node_index] = {"item_texture": item_texture, "stack_count_label" : stack_count_label}
			_node_slot_lookup[item_button] = node_index
			items[node_index] = null
			_free_spaces.append(node_index)
			pos.x += gap_adjustment.x
		pos.y += gap_adjustment.y
		pos.x = initial_slot_position.x
	item_slot_template.queue_free()
	item_texture_template.queue_free()
	
	if not has_hotbar:
		inventory_panel.texture = null	


func full():
	return _free_spaces.size() == 0


func append(item : Interact_Area):
	if not full():
		var next_space = _free_spaces.pop_front()
		var my_item = item.duplicate()
		add_child(my_item)
		items[next_space] = my_item
		if item.get_parent() is Sprite2D:
			item.get_parent().queue_free()
		_free_spaces.sort()
		return true
	else:
		return false


func find_items(item_to_find : Interact_Area):
	var found_items = []
	for id in items:
		var my_item = items[id]
		if my_item != null and not my_item.is_queued_for_deletion() and my_item.interact_label == item_to_find.interact_label:
			found_items.append(my_item)
	return found_items


func drop_at(node_id : Vector2i):
	items[node_id].queue_free()
	_free_spaces.append(node_id)
	_free_spaces.sort()
	update_inventory_canvas()


func insert_at_stackable(new_item : Interact_Area, old_item : Interact_Area):
	# Give all to new_item, and remainder to old_item
	increment_stackable(old_item, new_item, old_item.collectible_resource)


func insert_at(item : Dictionary, node_id : Vector2i, delete : bool = false):  # Insert into a specific slot
	var interactable = item["interactable"]
	var old_item : Dictionary = {}
	if not delete and items[node_id] != null and not items[node_id].is_queued_for_deletion():
		var old_interactable = items[node_id]
		var used_up = false
		if old_interactable.collectible_resource.stackable and old_interactable.interact_label == interactable.interact_label:
			insert_at_stackable(interactable, old_interactable)
			used_up = old_interactable.collectible_count <= 0
		if used_up:
			old_interactable.queue_free()
		else:
			old_item = {"container" : self, "node_id" : node_id, "interactable": old_interactable, "texture": _canvas_nodes[node_id]["item_texture"]}
			item["container"].insert_at(old_item, item["node_id"], true)
	
	items[node_id] = interactable
	
	# Clean up
	item = {}
	interactable.interact_icon.queue_free()
	_free_spaces.erase(node_id)
	_free_spaces.sort()
	update_inventory_canvas()
	# return old_item


func increment_stackable(item : Interact_Area, found_item : Interact_Area, resource : CollectibleResource):
	if found_item.collectible_count < resource.max_stack:
		if (found_item.collectible_count + item.collectible_count) < resource.max_stack:
			found_item.collectible_count += item.collectible_count
			item.collectible_count = 0
		else:
			item.collectible_count -= (resource.max_stack - found_item.collectible_count)
			found_item.collectible_count = resource.max_stack


func insert_stackable(item : Interact_Area, resource : CollectibleResource):
	var found_items = find_items(item)
	if found_items.is_empty():
		return(append(item))
	else:
		for found_item in found_items:
			increment_stackable(item, found_item, resource)
		if item.collectible_count > 0:
			return(append(item))
		elif item.get_parent() is Sprite2D:
			item.get_parent().queue_free()
	return(true)


func insert_item(item : Interact_Area):
	var insert_success = false
	var resource = item.collectible_resource
	if resource.stackable:
		insert_success = insert_stackable(item, resource)
	else:
		insert_success = append(item)
		
	if insert_success:
		update_inventory_canvas()
	return insert_success


func update_inventory_canvas():
	for dict_pos in items:
		var item = items[dict_pos]
		if item != null and not item.is_queued_for_deletion():
			_canvas_nodes[dict_pos]["item_texture"].texture = item.collectible_resource.icon
			if item.collectible_resource.stackable:
				_canvas_nodes[dict_pos]["stack_count_label"].text = "x" + str(item.collectible_count)
			else:
				_canvas_nodes[dict_pos]["stack_count_label"].text = ""
			# TODO: Add a delete function
		else:
			_canvas_nodes[dict_pos]["item_texture"].texture = Texture2D
			_canvas_nodes[dict_pos]["stack_count_label"].text = ""


func open():
	self.visible = true
	if has_close_button:
		$CloseButton.visible = true
	else:
		$CloseButton.visible = false
	opened = true


func close():
	self.visible = false
	opened = false
	inventory_closed.emit()


func _on_close_button_button_up():
	close()


func _on_item_slot_template_slot_pressed(which : TextureButton):
	print(which, 'pressed')
	var node_id = _node_slot_lookup[which]
	var interactable = items[node_id]
	var item = {}
	
	if interactable != null and not interactable.is_queued_for_deletion():
		interactable.interact_icon = Sprite2D.new()
		interactable.interact_icon.texture = interactable.collectible_resource.icon
		# interactable.add_child(interactable.interact_icon)
		var my_item = interactable.duplicate()
		add_child(my_item.interact_icon)
		add_child(my_item)
		item = {"container" : self, "node_id" : node_id, "interactable": my_item}
	else:
		item = {"container" : self, "node_id" : node_id}
	
	var picked = GlobalNode.pick_or_place(item)
	if picked:
		drop_at(node_id)

