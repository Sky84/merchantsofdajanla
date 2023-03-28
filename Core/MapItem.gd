extends Node3D
class_name MapItem

@export var _interactive_label_container_path: NodePath;
@export var _is_interactive := false;

var _interactive_label_container: Node3D = null;

var id: String;
var _owner: String;

func is_interactive() -> bool:
	return _is_interactive;

func _ready():
	if not _interactive_label_container_path.is_empty():
		_interactive_label_container = get_node(_interactive_label_container_path);

func _update_id():
	id = NodeUtils.get_map_item_id(self);

func interact(_interract_owner_id: String) -> void:
	pass

func get_interactive_label_container() -> Node3D:
	if not _is_interactive:
		return null;
	return _interactive_label_container;
