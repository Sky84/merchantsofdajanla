extends Node3D

var _subjects: Array[Node3D] = [];
var _occluders: Array[Node3D] = [];
var _failed := false;

func _ready() -> void:
	if "--game" in OS.get_cmdline_user_args():
		await _check_game_scene();
		return;
	var env = Environment.new();
	env.background_mode = Environment.BG_COLOR;
	env.background_color = Color(0.85, 0.8, 0.6);
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;
	env.ambient_light_color = Color.WHITE;
	env.ambient_light_energy = 0.6;
	$Environment.environment = env;
	$Camera3D.position = Vector3(0, 15, 20);
	$Camera3D.look_at(Vector3(0, 3, 0));
	$Camera3D.projection = Camera3D.PROJECTION_ORTHOGONAL;
	$Camera3D.size = 23;
	var ground = MeshInstance3D.new();
	var plane = PlaneMesh.new();
	plane.size = Vector2(60, 60);
	ground.mesh = plane;
	var ground_material = StandardMaterial3D.new();
	ground_material.albedo_color = Color(0.72, 0.65, 0.42);
	ground.material_override = ground_material;
	add_child(ground);

	# Extract the actual player's scene and materials without starting the story
	# or touching user://savegame.json. Base Alive retains the production hook.
	var game = load("res://Game.tscn").instantiate();
	var player = game.get_node("Player");
	game.remove_child(player);
	game.get_node("CanvasLayer").tooltip.free();
	game.free();
	player.set_script(preload("res://Core/Alive.gd"));
	player.position = Vector3(-7.4, 0, -1.0);
	add_child(player);
	_freeze_human(player);
	_subjects.append(player);

	var citizen = load("res://PNJs/Citizen/Citizen.tscn").instantiate();
	citizen.set_script(preload("res://Core/Alive.gd"));
	citizen.position = Vector3(0, 0, -1.0);
	add_child(citizen);
	_freeze_human(citizen);
	_subjects.append(citizen);

	var sawaji = load("res://PNJs/Sawaji/Sawaji.tscn").instantiate();
	sawaji.variant = "_marron";
	sawaji.tint_random = 0;
	sawaji.position = Vector3(7, 0, -1.0);
	add_child(sawaji);
	sawaji.set_process(false);
	sawaji.sprite.stop();
	_subjects.append(sawaji);

	for x in [-7, 0]:
		var tree = load("res://Map/Objects/Tree.tscn").instantiate();
		tree.position.x = x;
		tree.simulate_wind = false; # Stable image comparisons.
		add_child(tree);
		_occluders.append(tree);
	var occluder = MeshInstance3D.new();
	var box = BoxMesh.new();
	box.size = Vector3(2, 4, 0.5);
	occluder.mesh = box;
	var mat = StandardMaterial3D.new();
	mat.albedo_color = Color(0.3, 0.6, 0.3);
	occluder.material_override = mat;
	add_child(occluder);
	occluder.position = Vector3(7, 2, 1);
	_occluders.append(occluder); # Deliberately no collider.
	await _check_images("occluded", true);

	for obstacle in _occluders:
		obstacle.hide();
	await _check_images("exposed", false);
	# Mirroring/animation changes previously left copies facing the wrong way.
	for subject in _subjects:
		for sprite in preload("res://Core/Combat.gd")._sprites_of(subject):
			sprite.flip_h = true;
			sprite.frame = 2;
	await _check_images("exposed_flipped", false);
	for obstacle in _occluders:
		obstacle.show();
	await _check_images("occluded_flipped", true);
	$Camera3D.projection = Camera3D.PROJECTION_PERSPECTIVE;
	# Same tilt and lens as the gameplay camera, backed up to frame the fixtures.
	$Camera3D.position = Vector3(0, 20, 19);
	$Camera3D.rotation_degrees = Vector3(-43.0, 0, 0);
	await _check_images("perspective", true);
	for obstacle in _occluders:
		obstacle.hide();
	await _check_images("perspective_exposed", false);
	for subject in _subjects:
		subject.queue_free();
	await get_tree().process_frame;
	get_tree().quit(1 if _failed else 0);

func _freeze_human(human: Node3D) -> void:
	human.set_process(false);
	human.get_node("AnimationTree").active = false;
	human.get_node("ClothAnimations").set_process(false);
	for sprite in preload("res://Core/Combat.gd")._sprites_of(human):
		sprite.animation = &"idle";
		sprite.frame = 0;
		sprite.stop();

func _set_effect(enabled: bool) -> void:
	for subject in _subjects:
		var effect = subject.get_node("OcclusionSilhouette");
		effect.set_process(enabled);
		for sprite in subject.find_children("*", "AnimatedSprite3D", true, false):
			if sprite.has_meta(&"occlusion_pass"):
				sprite.visible = enabled;

func _capture() -> Image:
	for i in 3:
		await RenderingServer.frame_post_draw;
	return get_viewport().get_texture().get_image();

func _check_images(label: String, should_change: bool) -> void:
	_set_effect(false);
	var before = await _capture();
	before.save_png("res://tests/out_occlusion_%s_off.png" % label);
	_set_effect(true);
	var after = await _capture();
	after.save_png("res://tests/out_occlusion_%s_on.png" % label);
	var counts = [0, 0, 0];
	var split_left = $Camera3D.unproject_position(
		(_subjects[0].global_position + _subjects[1].global_position) * 0.5).x;
	var split_right = $Camera3D.unproject_position(
		(_subjects[1].global_position + _subjects[2].global_position) * 0.5).x;
	for y in after.get_height():
		for x in after.get_width():
			var a = before.get_pixel(x, y);
			var b = after.get_pixel(x, y);
			if abs(a.r - b.r) + abs(a.g - b.g) + abs(a.b - b.b) > 0.05:
				var index = 0 if x < split_left else (1 if x < split_right else 2);
				counts[index] += 1;
	for count in counts:
		if (should_change and count < 100) or (not should_change and count > 20):
			_failed = true;
			push_error("Unexpected silhouette coverage: %s %s" % [label, counts]);
	print("OCCLUSION ", label, " changed pixels (player/citizen/sawaji)=", counts);

func _check_game_scene() -> void:
	# Exercise PlayerController, UI, environment and the real gameplay camera.
	# Remove only the story before _ready, so this never loads/writes a save.
	name = "Root";
	$Environment.free();
	$DirectionalLight3D.free();
	$Camera3D.free();
	var game = load("res://Game.tscn").instantiate();
	game.get_node("StoryController").free();
	var player = game.get_node("Player");
	player.position = Vector3.ZERO;
	add_child(game);
	for i in 30:
		await get_tree().process_frame;
	var camera = game.get_node("Camera3D");
	camera.position = player.position - camera._offset;
	var tree = load("res://Map/Objects/Tree.tscn").instantiate();
	tree.simulate_wind = false;
	tree.position.x = 0.4;
	tree.position.z = 2.5;
	game.add_child(tree);
	var sawaji = load("res://PNJs/Sawaji/Sawaji.tscn").instantiate();
	sawaji.position = Vector3(3.3, 0, 0);
	sawaji.variant = "_marron";
	game.add_child(sawaji);
	var box = MeshInstance3D.new();
	var mesh = BoxMesh.new();
	mesh.size = Vector3(1.5, 3, 0.4);
	box.mesh = mesh;
	box.position = Vector3(3.3, 1.5, 2);
	game.add_child(box);
	_subjects = [player, sawaji];
	for subject in _subjects:
		subject.get_node("OcclusionSilhouette").process_mode = Node.PROCESS_MODE_ALWAYS;
	get_tree().paused = true;
	_set_effect(false);
	var before = await _capture();
	before.save_png("res://tests/out_occlusion_game_off.png");
	_set_effect(true);
	var after = await _capture();
	after.save_png("res://tests/out_occlusion_game_on.png");
	print("GAME OCCLUSION CAPTURED");
	get_tree().paused = false;
	get_tree().quit();
