extends Node3D
class_name MapItem

@export var _owner: String;

var id: String;

func is_interactive() -> bool:
	return get_node_or_null(InteractComponent.SCENE_NAME) != null;

func _update_id():
	id = NodeUtils.get_map_item_id(self);
