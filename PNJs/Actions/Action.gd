extends Node
class_name Action

var id: String;
var target: String;
var fallback: Action;

var navigation_mesh: NavigationMesh;

signal on_action_finished(id: String, next_action: Action);

func _init(_id: String, _target: String, _navigation_mesh: NavigationMesh , _fallback: Action = null) -> void:
	id = _id;
	target = _target;
	fallback = _fallback;
	navigation_mesh = _navigation_mesh;

func execute(params: Dictionary) -> void:
	printerr("Need implement execute function for Action and emit on_action_finished"+ id);
