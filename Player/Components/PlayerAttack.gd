extends Node

const ATTACK_RANGE := 2.8;
const ATTACK_HEIGHT := 2.0;
const ATTACK_COOLDOWN := 0.8;
var _cooldown := 0.0;

@onready var _player = get_parent();

func _process(delta: float) -> void:
	_cooldown = max(0.0, _cooldown - delta);
	if Input.is_action_just_pressed("attack"):
		try_attack();

func has_equipped_weapon() -> bool:
	return not _player.equipment.get_equipped_item("weapon").is_empty();

func can_attack() -> bool:
	return _cooldown <= 0.0 and not _player._is_blocked \
		and not _player.is_dead and has_equipped_weapon();

func try_attack() -> bool:
	if not can_attack():
		return false;
	_cooldown = ATTACK_COOLDOWN;
	var weapon = _player.equipment.get_equipped_item("weapon");
	var damage = int(weapon.get("damage", 0));
	for alive in get_tree().get_nodes_in_group(Alive.GROUP_NAME):
		if not _is_valid_target(alive):
			continue;
		var delta: Vector3 = alive.global_position - _player.global_position;
		if Vector2(delta.x, delta.z).length() <= ATTACK_RANGE \
				and absf(delta.y) <= ATTACK_HEIGHT:
			alive.take_damage(damage, _player);
	return true;

func _is_valid_target(target) -> bool:
	return target != _player and is_instance_valid(target) \
		and not target.get("is_dead") and target.has_method("take_damage");
