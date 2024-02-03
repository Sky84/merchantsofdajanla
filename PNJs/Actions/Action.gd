extends Node
class_name Action

var id: String;
var target: String;
var params: Array;

signal on_action_finished(id: String, owner_id: String, next_action: Action);

func _init(_id: String, _target: String, _params: Array, ) -> void:
	id = _id;
	target = _target;
	params = _params;

func execute(_params: Dictionary) -> void:
	printerr("Need implement execute function for Action and emit on_action_finished. action id is: "+ id);
