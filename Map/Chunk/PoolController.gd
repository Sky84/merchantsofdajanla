extends Node3D
class_name PoolController

var _current_index: int = 0;
var _loop_index = 0;

var loop_index: int:
	get:
		return _loop_index;

func move_instance(g_position: Vector3) -> Node3D:
	var instance = get_instance();
	_current_index = fmod(_current_index+1.0, get_child_count());
	instance.global_position = g_position;
	instance.show();
	if _current_index == 0:
		_loop_index = _loop_index + 1;
	return instance;

func get_instance() -> Node3D:
	return get_child(_current_index);
