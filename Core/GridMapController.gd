@tool
extends Node3D
class_name GridMapController

class Item:
	var _instance: Node3D;
	func _init(instance: Node3D):
		_instance = instance;
	
	var instance:
		get:
			return _instance;

@export var tile_size = 32;

@export var _grounds: Node3D;

var _items: Dictionary = {};

func init_grounds():
	for item in _grounds.get_children():
		set_cell_item(item.global_position, item);

func set_cell_item(global_tile_position: Vector3, cell_instance: Node3D) -> void:
	var instance_to_replace = get_cell_item(global_tile_position);
	if instance_to_replace != null:
		_grounds.remove_child(instance_to_replace);
		_items.erase(global_tile_position);
	if cell_instance == null:
		return;
	
	_items[global_tile_position] = Item.new(cell_instance);
	if !cell_instance.is_inside_tree():
		_grounds.add_child(cell_instance);
	cell_instance.global_position = global_tile_position;

func get_cell_item(global_tile_position: Vector3) -> Node3D:
	if _items.has(global_tile_position):
		return _items[global_tile_position].instance;
	else:
		return null;

# like get_used_cells
func get_items() -> Dictionary:
	return _items;

func map_to_local(map_position: Vector3) -> Vector3:
	return map_position - global_position;

