extends Node3D
class_name PoolController

var _current_index: int = 0;

func move_instance(g_position: Vector3) -> Node3D:
	var instance = get_instance();
	_current_index = fmod(_current_index+1.0, get_child_count());
	instance.global_position = g_position;
	instance.show();
	print(_current_index == 0)
	return instance;

func get_instance() -> Node3D:
	return get_child(_current_index);
