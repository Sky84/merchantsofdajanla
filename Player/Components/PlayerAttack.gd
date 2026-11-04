extends Node

const ATTACK_RANGE := 2.0;
const BASE_DAMAGE := 5; # coups à mains nues
const ATTACK_COOLDOWN := 0.8;
var _cooldown := 0.0;

@onready var _player = get_parent();

func _process(delta: float) -> void:
	_cooldown = max(0.0, _cooldown - delta);
	if Input.is_action_just_pressed("attack") and not _player._is_blocked and not _player.is_dead:
		_attack();

func _attack() -> void:
	_cooldown = ATTACK_COOLDOWN;
	var damage = int(_player.equipment.get_equipped_item("weapon").get("damage", BASE_DAMAGE));
	for alive in get_tree().get_nodes_in_group(Alive.GROUP_NAME):
		if alive == _player or not is_instance_valid(alive) or alive.get("is_dead"):
			continue;
		if _player.global_position.distance_to(alive.global_position) <= ATTACK_RANGE:
			alive.take_damage(damage, _player);
