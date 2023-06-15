extends Node
class_name Action

var id: String;
var target: String;
var params: Array;

var navigation_mesh: NavigationMesh;

signal on_action_finished(id: String, next_action: Action);

func _init(_id: String, _target: String, _params: Array, _navigation_mesh: NavigationMesh) -> void:
	id = _id;
	target = _target;
	params = _params;
	navigation_mesh = _navigation_mesh;

func execute(params: Dictionary) -> void:
	printerr("Need implement execute function for Action and emit on_action_finished"+ id);
