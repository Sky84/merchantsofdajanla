extends Node

const FakeAlive = preload("res://tests/FakeAlive.gd");

func _ready() -> void:
	var save = FileAccess.open("user://savegame.json", FileAccess.WRITE);
	save.store_string(JSON.stringify({"intro_done": true, "pos": [0, 0, 0]}));
	save.close();
	var game = load("res://Game.tscn").instantiate();
	add_child(game);
	for i in 180:
		await get_tree().process_frame;
	var player: Player = game.get_node("Player");
	assert(player.attack.has_equipped_weapon());

	var citizen = _fake("Citizen", "human", player.global_position + Vector3(1.5, 0, 0));
	var merchant = _fake("Merchant", "human", player.global_position + Vector3(-1.5, 0, 0));
	var sawaji = _fake("Sawaji", "sawaji", player.global_position + Vector3(0, 0, 2.5));
	var far_alive = _fake("FarAlive", "human", player.global_position + Vector3(5, 0, 0));
	var dead_alive = _fake("DeadAlive", "human", player.global_position + Vector3(1, 0, 1));
	dead_alive.is_dead = true;

	var attacked = player.attack.try_attack();
	assert(attacked);
	assert(citizen.alive_status.health.value == 15);
	assert(merchant.alive_status.health.value == 15);
	assert(sawaji.alive_status.health.value == 15);
	assert(far_alive.alive_status.health.value == 30);
	assert(dead_alive.alive_status.health.value == 30);
	assert(not player.attack.try_attack()); # cooldown blocks repeated clicks

	Input.action_press("attack");
	assert(player.get_state().is_attacking);
	Input.action_release("attack");

	player.equipment._equipped.erase("weapon");
	player.attack._cooldown = 0.0;
	assert(not player.attack.try_attack());
	Input.action_press("attack");
	assert(not player.get_state().is_attacking);
	Input.action_release("attack");

	print("PLAYER ATTACK: citizen, merchant and sawaji damaged; range, cooldown and unequip checks passed");
	get_tree().quit();

func _fake(node_name: String, species: String, at: Vector3):
	var alive = FakeAlive.new();
	alive.name = node_name;
	alive.species_id = species;
	add_child(alive);
	alive.global_position = at;
	return alive;
