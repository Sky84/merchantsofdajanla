extends Node

func _ready() -> void:
	var f = FileAccess.open("user://savegame.json", FileAccess.WRITE);
	f.store_string(JSON.stringify({"intro_done": true, "pos": [0, 0, 0]}));
	f.close();
	var game = load("res://Game.tscn").instantiate();
	add_child(game);
	for i in 150:
		await get_tree().process_frame;
	var player = game.get_node("Player");
	player.take_damage(40);
	for i in 15:
		await get_tree().process_frame;
	await RenderingServer.frame_post_draw;
	get_viewport().get_texture().get_image().save_png("res://tests/out_ghost_during.png");
	for i in 80:
		await get_tree().process_frame;
	await RenderingServer.frame_post_draw;
	get_viewport().get_texture().get_image().save_png("res://tests/out_ghost_after.png");
	print("GHOST CAPTURED");
	get_tree().quit();
