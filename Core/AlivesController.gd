extends Node

# alives[owner_id] = Alive
var _alives: Dictionary = {};

# Called when the node enters the scene tree for the first time.
func _ready():
	AliveEvents.on_alive_ready.connect(_register_alive);

func get_alive_by_owner_id(owner_id: String) -> Alive:
	return _alives[owner_id] if owner_id in _alives else null;

func _register_alive(alive: Alive) -> void:
	_alives[alive._owner_id] = alive;

func set_alive_blocked(value: bool) -> void:
	for alive_owner_id in _alives:
		var alive = _alives[alive_owner_id];
		print(alive_owner_id)
		if alive is CitizenController:
			alive._is_blocked = value;
			alive.set_process(not value);
			print(alive is CitizenController, alive.inactive)
			if alive is CitizenController:
				alive.inactive = value;
				print(alive.inactive)