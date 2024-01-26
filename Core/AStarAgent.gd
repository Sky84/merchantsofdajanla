extends Node3D
class_name AStarAgent

var target_desired_distance: int = 2;

var _path_finding: PathFinding;

var _current_path: Array = [];

var _target_position: Vector3;
var target_position: Vector3:
	get:
		return _target_position;
	set(value):
		_target_position = value;
		_current_path = _path_finding.find_path(global_position, _target_position);
		#_debug_path();

signal target_reached;

func _init(path_finding: PathFinding):
	_path_finding = path_finding;

func _process(delta):
	var distance_to_target = global_position.distance_to(_target_position);
	var distance_to_next_point = global_position.distance_to(get_next_path_position());
	if _current_path.size() > 0 and distance_to_target <= target_desired_distance:
		target_reached.emit();
		_current_path = [];
	elif distance_to_next_point <= target_desired_distance:
		_current_path.pop_front();

func _debug_path():
	for child in _path_finding.get_children():
		if child.global_position in _current_path:
			_path_finding.remove_child(child);
	for point in _current_path:
		var debug_mesh = DebugMesh.new(Vector3(0.3, 1, 0.3));
		_path_finding.add_child(debug_mesh);
		debug_mesh.global_position = point;

func get_current_navigation_path() -> Array:
	return _current_path.duplicate();

func get_next_path_position():
	return _current_path.front() if _current_path.size() > 0 else global_position;
