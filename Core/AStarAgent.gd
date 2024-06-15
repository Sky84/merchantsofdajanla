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
		print(global_position, '+++', _target_position)
		print(_current_path)

signal target_reached;

func _init(path_finding: PathFinding):
	_path_finding = path_finding;

func _process(_delta):
	var distance_to_target = global_position.distance_to(_target_position);
	var distance_to_next_point = global_position.distance_to(get_next_path_position());
	if _current_path.size() > 0 and distance_to_target <= target_desired_distance:
		target_reached.emit();
		_current_path = [];
	elif distance_to_next_point <= target_desired_distance:
		_current_path.pop_front();
	if _path_finding.debug:
		_debug_path();

func _debug_path():
	if _current_path.size() > 1:
		DebugDraw3D.draw_point_path(_current_path, DebugDraw3D.POINT_TYPE_SQUARE)

func get_current_navigation_path() -> Array:
	return _current_path.duplicate();

func get_next_path_position():
	return _current_path.front() if _current_path.size() > 0 else global_position;
