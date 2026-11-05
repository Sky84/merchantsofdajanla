extends Node

const DIRECTIONS = {
	"up": Vector2i(0, -1),
	"right": Vector2i(1, 0),
	"down": Vector2i(0, 1),
	"left": Vector2i(-1, 0),
};

func _ready() -> void:
	var save = FileAccess.open("user://savegame.json", FileAccess.WRITE);
	save.store_string(JSON.stringify({"intro_done": true, "pos": [0, 0, 0]}));
	save.close();
	var game = load("res://Game.tscn").instantiate();
	add_child(game);
	for i in 180:
		await get_tree().process_frame;
	var player = game.get_node("Player");
	var map = get_tree().get_first_node_in_group("game_map");
	_validate_decorations(map);
	for action in DIRECTIONS:
		var start = _find_ramp_start(map, DIRECTIONS[action]);
		if start == null:
			print("RAMP ", action, " not found");
			continue;
		player.global_position = start;
		for i in 10:
			await get_tree().process_frame;
		var start_height = map.get_ground_height(player.global_position.x, player.global_position.z);
		var min_height = start_height;
		var max_height = start_height;
		var max_snap_error := 0.0;
		Input.action_press(action);
		for i in 300:
			await get_tree().process_frame;
			var ground = map.get_ground_height(player.global_position.x, player.global_position.z);
			if ground != null:
				min_height = minf(min_height, ground);
				max_height = maxf(max_height, ground);
				max_snap_error = maxf(max_snap_error, absf(player.global_position.y - ground));
		Input.action_release(action);
		await RenderingServer.frame_post_draw;
		get_viewport().get_texture().get_image().save_png(
			"res://tests/out_ramp_%s.png" % action);
		print("RAMP ", action, " range=", max_height - min_height,
			" snap_error=", max_snap_error, " end=", player.global_position);
	get_tree().quit();

func _validate_decorations(map) -> void:
	var count := 0;
	var max_error := 0.0;
	for x_chunks in map._chunks.values():
		for chunk in x_chunks.values():
			if chunk._terrain_heights.is_empty():
				continue;
			for decoration in chunk.decorations.get_children():
				if not decoration.has_meta(&"terrain_y_offset"):
					continue;
				var ground = map.get_ground_height(
					decoration.global_position.x, decoration.global_position.z);
				var visual_base = decoration.global_position.y \
					- float(decoration.get_meta(&"terrain_y_offset"));
				max_error = maxf(max_error, absf(visual_base - ground));
				count += 1;
	print("DECOR count=", count, " max_ground_error=", max_error);

func _find_ramp_start(map, direction: Vector2i) -> Variant:
	for x_chunks in map._chunks.values():
		for chunk in x_chunks.values():
			if chunk._terrain_heights.is_empty():
				continue;
			var levels: Array = chunk._terrain_heights;
			for cz in range(1, TerrainMesh.CELLS + 1):
				for cx in range(1, TerrainMesh.CELLS + 1):
					var neighbor_level = levels[cz + direction.y][cx + direction.x];
					var level = levels[cz][cx];
					if neighbor_level <= level:
						continue;
					var diff: int = neighbor_level - level;
					var local = Vector2(
						(cx - 0.5) * TerrainMesh.CELL_SIZE,
						(cz - 0.5) * TerrainMesh.CELL_SIZE);
					var distance = diff * TerrainMesh.RAMP_WIDTH + 0.5;
					if direction.x != 0:
						local.x += direction.x * (TerrainMesh.CELL_SIZE * 0.5 - distance);
					else:
						local.y += direction.y * (TerrainMesh.CELL_SIZE * 0.5 - distance);
					var world_x = chunk.global_position.x + local.x;
					var world_z = chunk.global_position.z + local.y;
					return Vector3(world_x, map.get_ground_height(world_x, world_z), world_z);
	return null;
