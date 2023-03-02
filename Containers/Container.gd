extends Node3D
class_name ItemsContainer

@export var _start_items_json_path: String;
@export var _container_owner: String;
@export var container_id: String;
@export var rows: int;
@export var columns: int;

var _start_items = {};
var _items = {};

# Called when the node enters the scene tree for the first time.
func _ready():
	if _start_items_json_path:
		_start_items = GameItems.get_start_items(_start_items_json_path);
	_items.merge(_start_items, true);
	ContainersController.register_container(container_id, rows, columns, _items, _container_owner);
	ContainersController.update(container_id, _items);

func _add_items(items_to_add:Dictionary):
	for id in items_to_add:
		var item_to_add = items_to_add[id];
		if _items.has(id):
			_items[id].amount += items_to_add.amount;
		else:
			_items[id] = item_to_add;
	ContainersController.update(container_id, _items);

func _remove_items(items_to_remove: Dictionary):
	for id in items_to_remove:
		var item_to_remove = items_to_remove[id];
		if _items.has(id):
			_items[id].amount -= item_to_remove.amount;
			if _items[id].amount < 1:
				_items[id].erase(id);
	ContainersController.update(container_id, _items);
