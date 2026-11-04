extends Node

func _ready() -> void:
	var scene = load("res://PNJs/Sawaji/Sawaji.tscn");
	var mods = [];
	for i in 6:
		var sawaji = scene.instantiate();
		add_child(sawaji);
		sawaji.position = Vector3(i * 5, 0, 0);
		await get_tree().process_frame;
		mods.append(sawaji.sprite.modulate);
		print("sawaji", i, " modulate=", sawaji.sprite.modulate);
	var distinct = {};
	for m in mods:
		distinct[m] = true;
	print("distinct tints=", distinct.size(), " / 6");
	var all_white = mods.all(func(m): return m == Color(1, 1, 1, 1));
	print("all white=", all_white);
	get_tree().quit();
