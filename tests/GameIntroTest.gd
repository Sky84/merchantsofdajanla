extends Node

func _ready() -> void:
	DirAccess.remove_absolute("user://savegame.json");
	var game = load("res://Game.tscn").instantiate();
	add_child(game);
	var modal_container = game.get_node("CanvasLayer/ModalContainer");
	var player = game.get_node("Player");
	var clicks = 0;
	var saw_modal = false;
	var empty_frames = 0;
	for i in 3600:
		await get_tree().process_frame;
		if modal_container.get_child_count() > 0:
			var modal = modal_container.get_child(0);
			if not saw_modal:
				saw_modal = true;
				for j in 30:
					await get_tree().process_frame;
				await RenderingServer.frame_post_draw;
				get_viewport().get_texture().get_image().save_png("res://tests/out_game.png");
				print("CAPTURED");
			var answers = modal.get_node_or_null("AnswersContainer");
			if answers == null or answers.get_child_count() == 0:
				continue;
			var ev = InputEventMouseButton.new();
			ev.pressed = true;
			ev.button_index = MOUSE_BUTTON_LEFT;
			answers.get_child(0)._gui_input(ev);
			clicks += 1;
			empty_frames = 0;
			for j in 20:
				await get_tree().process_frame;
		elif saw_modal:
			empty_frames += 1;
			if empty_frames > 150:
				break;
	print("clicks=", clicks, " player_blocked=", player._is_blocked, " modal_children=", modal_container.get_child_count());
	InventoryEvents.visibility_inventory.emit(true);
	for j in 30:
		await get_tree().process_frame;
	await RenderingServer.frame_post_draw;
	get_viewport().get_texture().get_image().save_png("res://tests/out_inventory.png");
	print("INVENTORY CAPTURED");
	var shirts = player.get_node("ClothAnimations/ShirtsAnimatedSprite3D");
	print("shirt frames before=", shirts.sprite_frames != null);
	player.unequip("shirt");
	for j in 15:
		await get_tree().process_frame;
	print("shirt frames after unequip=", shirts.sprite_frames != null, " equipped=", player.is_equipped("shirt"));
	await RenderingServer.frame_post_draw;
	get_viewport().get_texture().get_image().save_png("res://tests/out_unequip.png");
	player.equip("shirt_basic");
	for j in 10:
		await get_tree().process_frame;
	print("shirt frames after equip=", shirts.sprite_frames != null, " equipped=", player.is_equipped("shirt"));
	var esc = InputEventKey.new();
	esc.keycode = KEY_ESCAPE;
	esc.pressed = true;
	Input.parse_input_event(esc);
	for i in 40:
		await get_tree().process_frame;
	get_viewport().get_texture().get_image().save_png("res://tests/out_pause.png");
	print("PAUSE CAPTURED paused=", get_tree().paused);
	get_tree().quit();
