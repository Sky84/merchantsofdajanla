extends Node
class_name Action

var id: String;
var target: String;
var fallback: Action;

signal on_action_finished(id: String);

func _init(_id: String, _target: String, _fallback: Action = null) -> void:
	id = _id;
	target = _target;
	fallback = _fallback;

func execute(params: Dictionary) -> void:
	printerr("Need implement execute function for Action and emit on_action_finished"+ id);
