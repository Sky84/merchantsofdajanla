extends Node3D

func _ready() -> void:
	var env = Environment.new();
	env.background_mode = Environment.BG_COLOR;
	env.background_color = Color(0.85, 0.8, 0.6);
	$Environment.environment = env;
	var scene = load("res://PNJs/Sawaji/Sawaji.tscn");
	for i in 6:
		var sawaji = scene.instantiate();
		add_child(sawaji);
		sawaji.position = Vector3(i * 4 - 10, 0, 0);
		if i == 2:
			sawaji.sprite.modulate = Color(1, 0, 0); # test : un rouge pur doit ressortir
		print("sawaji", i, "modulate=", sawaji.sprite.modulate);
	await RenderingServer.frame_post_draw;
	await RenderingServer.frame_post_draw;
	get_viewport().get_texture().get_image().save_png("res://tests/out_sawaji_visual.png");
	print("CAPTURED");
	get_tree().quit();
