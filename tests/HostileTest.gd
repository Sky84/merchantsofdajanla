extends Node

const FakeAlive = preload("res://tests/FakeAlive.gd");

func _ready() -> void:
	var sawaji = load("res://PNJs/Sawaji/Sawaji.tscn").instantiate();
	add_child(sawaji);
	var pnj_target = _spawn_target("PNJ_target", "human", Vector3(3, 0, 0));
	var player_target = _spawn_target("Player_target", "human", Vector3(-3, 0, 0));
	var same_species = _spawn_target("Sawaji_friend", "sawaji", Vector3(4, 0, 0));
	for i in 900:
		await get_tree().process_frame;
	print("pnj_target health=", pnj_target.alive_status.health.value, " dead=", pnj_target.is_dead);
	print("player_target health=", player_target.alive_status.health.value, " dead=", player_target.is_dead);
	print("sawaji_friend health=", same_species.alive_status.health.value, " dead=", same_species.is_dead);
	print("sawaji tint=", sawaji.sprite.modulate, " anim=", sawaji.sprite.animation);
	get_tree().quit();

func _spawn_target(n: String, species: String, pos: Vector3):
	var target = CharacterBody3D.new();
	target.set_script(FakeAlive);
	target.name = n;
	target.species_id = species;
	add_child(target);
	target.global_position = pos;
	return target;
