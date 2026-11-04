extends Node3D

func _ready() -> void:
	if "--world" in OS.get_cmdline_user_args():
		await _check_world();
		return;
	var chunk = load("res://Map/Chunk/chunk.tscn").instantiate();
	chunk.position = Vector3(-32, 0, -32);
	add_child(chunk);
	var ground_material = StandardMaterial3D.new();
	ground_material.albedo_color = Color(0.75, 0.65, 0.42);
	chunk.mesh_instance.material_override = ground_material;
	$Camera3D.position = Vector3(0, 16, 20);
	$Camera3D.look_at(Vector3.ZERO);
	var environment = WorldEnvironment.new();
	environment.environment = Environment.new();
	environment.environment.background_mode = Environment.BG_COLOR;
	environment.environment.background_color = Color(0.7, 0.7, 0.7);
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;
	environment.environment.ambient_light_color = Color.WHITE;
	environment.environment.ambient_light_energy = 0.7;
	add_child(environment);
	# These are the actual tilted decoration colliders, not substitute boxes.
	var decorations = ["SmallCactus", "BigCactus", "Tree", "SmallCactus"];
	var sawajis = [];
	var ranges = [];
	for i in 4:
		var decoration = load("res://Map/Objects/%s.tscn" % decorations[i]).instantiate();
		decoration.position.x = i * 6 - 9;
		decoration.simulate_wind = false;
		add_child(decoration);
		var sawaji = load("res://PNJs/Sawaji/Sawaji.tscn").instantiate();
		var direction = -1 if i == 3 else 1;
		sawaji.position = Vector3(i * 6 - 9, 0, -4 * direction);
		sawaji.aggro_range = 0;
		sawaji.same_species_aggression_chance = 0;
		sawaji.wander_speed_ratio = 1;
		sawaji.variant = "_marron";
		add_child(sawaji);
		sawaji._home_position = sawaji.position;
		sawaji._wander_target = sawaji.position + Vector3(0, 0, 12 * direction);
		sawaji._wander_timer = 1000;
		sawajis.append(sawaji);
		ranges.append(Vector2.ZERO);
	var captured := false;
	var tag = "baseline" if "--baseline" in OS.get_cmdline_user_args() else "fixed";
	for frame in 300:
		await get_tree().process_frame;
		for i in sawajis.size():
			var y = sawajis[i].position.y;
			ranges[i].x = minf(ranges[i].x, y);
			ranges[i].y = maxf(ranges[i].y, y);
			if y < -0.15 and not captured:
				captured = true;
				await RenderingServer.frame_post_draw;
				get_viewport().get_texture().get_image().save_png(
					"res://tests/out_ground_%s_sinking.png" % tag);
	var failed := false;
	for i in sawajis.size():
		print("GROUND ", decorations[i], " min/max y=", ranges[i],
			" final=", sawajis[i].position);
		if absf(ranges[i].x) > 0.02 or absf(ranges[i].y) > 0.02:
			failed = true;
	for sawaji in sawajis:
		sawaji.set_process(false);
	await RenderingServer.frame_post_draw;
	get_viewport().get_texture().get_image().save_png("res://tests/out_ground_%s.png" % tag);
	get_tree().quit(1 if failed else 0);

func _check_world() -> void:
	name = "Root";
	$Camera3D.free();
	$DirectionalLight3D.free();
	var game = load("res://Game.tscn").instantiate();
	game.get_node("StoryController").free(); # Do not read/write the player's save.
	game.get_node("Player").position = Vector3.ZERO;
	add_child(game);
	seed(1234);
	game.get_node("GameMapController")._savage_chunk_noise.seed = 42;
	var min_height := 0.0;
	var max_height := 0.0;
	var captured := false;
	var tag = "baseline" if "--baseline" in OS.get_cmdline_user_args() else "fixed";
	var count := 0;
	for frame in 600:
		await get_tree().process_frame;
		count = 0;
		for alive in get_tree().get_nodes_in_group(Alive.GROUP_NAME):
			if not alive is HostileController or alive.is_dead:
				continue;
			count += 1;
			min_height = minf(min_height, alive.global_position.y);
			max_height = maxf(max_height, alive.global_position.y);
			if alive.global_position.y < -0.15 and not captured:
				captured = true;
				print("SINKING at ", alive.global_position);
				for i in alive.get_slide_collision_count():
					var collision = alive.get_slide_collision(i);
					var obstacle = collision.get_collider();
					print("collision=", obstacle.get_path(),
						" normal=", collision.get_normal(),
						" decoration_transform=", obstacle.get_parent().global_transform);
				# Reveal existing chunks around the observed entity without
				# moving the player or generating a different test world.
				for column in game.get_node("GameMapController")._chunks.values():
					for chunk in column.values():
						chunk.show();
				var camera = game.get_node("Camera3D");
				camera.set_process(false);
				camera.position = Vector3(alive.position.x, 0, alive.position.z) - camera._offset;
				await RenderingServer.frame_post_draw;
				get_viewport().get_texture().get_image().save_png(
					"res://tests/out_ground_world_%s.png" % tag);
	print("WORLD sawajis=", count, " min/max y=", Vector2(min_height, max_height));
	if not captured:
		var closest: HostileController;
		for alive in get_tree().get_nodes_in_group(Alive.GROUP_NAME):
			if alive is HostileController and not alive.is_dead:
				if closest == null or alive.position.length_squared() < closest.position.length_squared():
					closest = alive;
		if closest != null:
			for column in game.get_node("GameMapController")._chunks.values():
				for chunk in column.values():
					chunk.show();
			var camera = game.get_node("Camera3D");
			camera.set_process(false);
			camera.position = closest.global_position - camera._offset;
			await RenderingServer.frame_post_draw;
			get_viewport().get_texture().get_image().save_png(
				"res://tests/out_ground_world_%s.png" % tag);
	get_tree().quit(1 if count == 0 or min_height < -0.02 or max_height > 0.02 else 0);
