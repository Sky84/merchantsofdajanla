extends Node3D

func _ready() -> void:
	var scene = load("res://PNJs/Sawaji/Sawaji.tscn");
	var sawajis = [];
	for i in 4:
		var sawaji = scene.instantiate();
		add_child(sawaji);
		sawaji.position = Vector3(i * 4 - 6, 0, 0);
		sawajis.append(sawaji);
	var anomalies = [];
	for frame in 2000:
		await get_tree().process_frame;
		for sawaji in sawajis:
			if not is_instance_valid(sawaji):
				if not anomalies.any(func(a): return a.begins_with(str(sawaji) + " freed")):
					anomalies.append(str(sawaji) + " freed at frame " + str(frame));
				continue;
			if sawaji.is_dead:
				continue;
			if not sawaji.sprite.visible:
				anomalies.append(str(sawaji.name) + " sprite.visible=false at " + str(frame));
				sawaji.sprite.visible = true;
			if sawaji.sprite.sprite_frames == null:
				anomalies.append(str(sawaji.name) + " frames null at " + str(frame));
			if sawaji.sprite.modulate.a < 0.9:
				anomalies.append(str(sawaji.name) + " alpha=" + str(sawaji.sprite.modulate.a) + " at " + str(frame));
			if abs(sawaji.global_position.y) > 3.0:
				anomalies.append(str(sawaji.name) + " y=" + str(sawaji.global_position.y) + " at " + str(frame));
	print("frames done, anomalies: ", anomalies.size());
	for a in anomalies.slice(0, 10):
		print("  - ", a);
	for sawaji in sawajis:
		if is_instance_valid(sawaji):
			print("final: ", sawaji.name, " pos=", sawaji.global_position, " visible=", sawaji.sprite.visible, " dead=", sawaji.is_dead);
	get_tree().quit();
