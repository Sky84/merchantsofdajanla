extends Node3D
class_name ItemsContainer

@export var _start_items_json_path: String;
@export var _items_container_view_path: NodePath;

@onready var _view: Panel = get_node(_items_container_view_path);
var _start_items;
var _items = {};

# Called when the node enters the scene tree for the first time.
func _ready():
	if _view == null:
		printerr('_view is null or not set');
		return;
	_view.ready.connect(_on_view_ready);

func _on_view_ready():
	if _start_items_json_path:
		_start_items = GameItems.get_start_items(_start_items_json_path);
		_add_items(_start_items);

func _add_items(items_to_add:Dictionary):
	for id in items_to_add:
		var item_to_add = items_to_add[id];
		if _items.has(id):
			_items[id].amount += items_to_add.amount;
		else:
			_items[id] = item_to_add;
	_update_view();

func _remove_items(items_to_remove: Dictionary):
	for id in items_to_remove:
		var item_to_remove = items_to_remove[id];
		if _items.has(id):
			_items[id].amount -= item_to_remove.amount;
			if _items[id].amount < 1:
				_items[id].erase(id);
	_update_view();

func _update_view():
	InventoryEvents.emit_signal("container_data_changed", _view.container_id, _items.duplicate(true));
