extends Node

func _ready() -> void:
	var save = FileAccess.open("user://savegame.json", FileAccess.WRITE);
	save.store_string(JSON.stringify({"intro_done": true, "pos": [0, 0, 0]}));
	save.close();
	var game = load("res://Game.tscn").instantiate();
	add_child(game);
	for i in 150:
		await get_tree().process_frame;
	var player = game.get_node("Player");
	player.animation_tree.active = false;
	var body: AnimatedSprite3D = player.get_node("ClothAnimations/SkinsAnimatedSprite3D");
	var weapon: WeaponAttachment3D = player.get_node("ClothAnimations/WeaponsAnimatedSprite3D");
	var profile := weapon.hold_profile;
	for animation in [&"idle", &"walk", &"run", &"hit"]:
		body.animation = animation;
		var frame_count = body.sprite_frames.get_frame_count(animation);
		for frame in frame_count:
			body.frame = frame;
			weapon.sync_to_source();
			assert(weapon.animation == animation);
			assert(weapon.frame == mini(frame,
				weapon.sprite_frames.get_frame_count(animation) - 1));
			assert(weapon.offset == profile.get_offset(animation, frame));
		body.frame = frame_count / 2;
		await RenderingServer.frame_post_draw;
		get_viewport().get_texture().get_image().save_png(
			"res://tests/out_weapon_%s.png" % animation);
		print("WEAPON ", animation, " frames=", frame_count,
			" offset=", weapon.offset);
	get_tree().quit();
