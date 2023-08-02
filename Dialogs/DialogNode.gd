class_name DialogNode

var _id: String;
var _next_nodes: Array;
var value: String;
var callback_name: String;
var callback_params: Array;

var next_nodes: Array:
	get:
		return _next_nodes;

var id: String:
	get:
		return _id;

var has_callback: bool:
	get:
		return callback_name.length() > 0;

var has_next_nodes: bool:
	get:
		return _next_nodes.size() > 0;

func _init(id: String, val: String, cb_name: String = '', cb_params: Array = [], next_nodes: Array = []):
	_id = id;
	value = val;
	_next_nodes = next_nodes;
	callback_name = cb_name;
	callback_params = cb_params;
