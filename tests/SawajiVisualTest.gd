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
	var occluder = MeshInstance3D.new();
	var box = BoxMesh.new();
	box.size = Vector3(8, 6, 0.5);
	occluder.mesh = box;
	var mat = StandardMaterial3D.new();
	mat.albedo_color = Color(0.3, 0.6, 0.3);
	occluder.material_override = mat;
	add_child(occluder);
	occluder.position = Vector3(0, 3, 4); # devant les sawajis du milieu
	await RenderingServer.frame_post_draw;
	await RenderingServer.frame_post_draw;
	get_viewport().get_texture().get_image().save_png("res://tests/out_sawaji_visual.png");
	print("CAPTURED");
	get_tree().quit();
