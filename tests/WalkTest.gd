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
	var dirs = {"up": 300, "right": 300, "down": 300, "left": 300};
	for d in dirs:
		Input.action_press(d);
		for i in dirs[d]:
			await get_tree().process_frame;
		Input.action_release(d);
		await RenderingServer.frame_post_draw;
		get_viewport().get_texture().get_image().save_png("res://tests/out_walk_%s.png" % d);
		print("WALK ", d, " pos=", player.global_position, " blocked=", player._is_blocked);
	get_tree().quit();
