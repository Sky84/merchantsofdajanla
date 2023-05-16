extends Node

# alives[owner_id] = Alive
var _alives: Dictionary = {};

# Called when the node enters the scene tree for the first time.
func _ready():
	AliveEvents.on_alive_ready.connect(_register_alive);

func get_alive_by_owner_id(owner_id: String) -> Alive:
	return _alives[owner_id];

func _register_alive(alive: Alive) -> void:
	_alives[alive._owner_id] = alive;
