extends Node

func _ready() -> void:
	var f = FileAccess.open("user://savegame.json", FileAccess.WRITE);
	f.store_string(JSON.stringify({"intro_done": true, "pos": [0, 0, 0]}));
	f.close();
	var game = load("res://Game.tscn").instantiate();
	add_child(game);
	for i in 150:
		await get_tree().process_frame;
	var bar = game.get_node("CanvasLayer/ShortcutBar");
	print("view container_id=", bar.container_id, " linked=", bar.items_container.container_id, " registered=", ContainersController._containers.keys());
	print("items_container children=", bar._items_container.get_child_count(), " margin_visible=", bar.get_node("MarginContainer").visible);
	var player = game.get_node("Player");
	var equipment_cid = "equipment_" + player._owner_id;
	var eq_slots = ContainersController.get_container_data(equipment_cid);
	print("equipment cells: 0=", eq_slots[0][0].get("id"), " 1=", eq_slots[1][0].get("id"), " 2=", eq_slots[2][0].get("id"));
	var preview = game.get_node("CanvasLayer/Inventory").get_children().filter(func(c): return c.has_method("_refresh_slots"))[0];
	preview._on_equip_slot_pressed(1, 0);
	for i in 10:
		await get_tree().process_frame;
	print("cursor item=", ContainersController.current_item.value.get("id"), " shirt equipped=", player.is_equipped("shirt"), " layer visible=", player.get_node("ClothAnimations/ShirtsAnimatedSprite3D").visible);
	InventoryEvents.visibility_inventory.emit(true);
	for i in 30:
		await get_tree().process_frame;
	await RenderingServer.frame_post_draw;
	get_viewport().get_texture().get_image().save_png("res://tests/out_equip_drag.png");
	var map = get_tree().get_first_node_in_group("game_map");
	var samples = [];
	for dz in range(-4, 5, 2):
		var row = [];
		for dx in range(-4, 5, 2):
			var h = map.get_ground_height(player.global_position.x + dx * 8, player.global_position.z + dz * 8);
			row.append("null" if h == null else "%.1f" % h);
		samples.append(str(row));
	print("heights grid: ", samples);
	for probe in [[0.0,0.0],[12.0,0.0],[24.0,0.0],[36.0,0.0],[48.0,0.0],[24.0,24.0],[48.0,48.0]]:
		player.global_position = Vector3(probe[0], 0.0, probe[1]);
		for i in 10:
			await get_tree().process_frame;
		var gh = map.get_ground_height(probe[0], probe[1]);
		print("probe ", probe, " h=", gh, " player.y=", player.global_position.y);
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
