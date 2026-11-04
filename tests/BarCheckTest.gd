extends Node

func _ready() -> void:
	var f = FileAccess.open("user://savegame.json", FileAccess.WRITE);
	f.store_string(JSON.stringify({"intro_done": true, "pos": [0, 0, 0]}));
	f.close();
	var game = load("res://Game.tscn").instantiate();
	add_child(game);
	for i in 150:
		await get_tree().process_frame;
	await RenderingServer.frame_post_draw;
	var img = get_viewport().get_texture().get_image();
	img.save_png("res://tests/out_bar_full.png");
	var size = get_viewport().get_visible_rect().size;
	var crop = img.get_region(Rect2i(size.x / 2 - 230, size.y - 130, 460, 130));
	crop.save_png("res://tests/out_bar_scene.png");
	print("BAR CAPTURED");
	get_tree().quit();
