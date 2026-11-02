extends CharacterBody3D

var species_id := "human";
var _owner_id := "";
var is_dead := false;
var alive_status := {"health": {"value": 30, "max": 30}};

func _ready() -> void:
	add_to_group(Alive.GROUP_NAME);
	_owner_id = name;

func take_damage(amount: int, _source = null) -> void:
	if is_dead:
		return;
	alive_status.health.value = clampi(alive_status.health.value - amount, 0, alive_status.health.max);
	if alive_status.health.value <= 0:
		is_dead = true;
