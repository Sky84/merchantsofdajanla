extends Node3D
class_name PoolController

func add_instance(g_position: Vector3) -> Node3D:
	var instance = get_instance();
	move_child(instance, get_child_count());
	instance.global_position = g_position;
	return instance;
	
func get_instance() -> Node3D:
	return get_child(0);
