extends Node3D
class_name ItemsContainer

@export var _start_items_json_path: String;
@export var _container_owner: String;
@export var container_id: String;
@export var rows: int;
@export var columns: int;
@export var _is_main_container_for_owner: bool;

var _start_items = {};
var _items = {};

# Called when the node enters the scene tree for the first time.
func _ready():
	if _start_items_json_path:
		_start_items = GameItems.get_start_items(_start_items_json_path);
	_items.merge(_start_items, true);
	ContainersController.register_container(container_id, rows, columns, _items, _container_owner, _is_main_container_for_owner);
	ContainersController.update(container_id, _items);
