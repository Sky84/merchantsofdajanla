extends Control

var _dialog_scene: PackedScene = preload("res://UI/Modals/DialogModal/DialogModal.tscn");
var _fake_pnj;

func _ready() -> void:
	await get_tree().process_frame;
	_fake_pnj = _make_fake_pnj();
	await _test_case("long", "Anna", "Bonjour nouvelle tête ! J'ai entendu parler de vous et de votre envie d'ouvrir un commerce. Si tu veux j'ai quelques conseils de base !", [
		{"text": "Euh...", "dialog_node_id": "a"},
		{"text": "Bonjour ! Oui, je vous écoute.", "dialog_node_id": "b"},
	], Vector2(700, 400), _fake_pnj);
	await _test_case("short", "Anna", "Salut.", [
		{"text": "OK", "dialog_node_id": "a"},
	], Vector2(600, 400), null);
	await _test_case("longanswer", "Merchant", "Que voulez-vous acheter aujourd'hui dans ma modeste boutique ?", [
		{"text": "Je voudrais acheter trois pommes de terre et un sac de blé s'il vous plaît", "dialog_node_id": "a"},
		{"text": "Rien", "dialog_node_id": "b"},
		{"text": "Au revoir", "dialog_node_id": "c"},
	], Vector2(1300, 400), _fake_pnj);
	print("TEST DONE");
	get_tree().quit();

func _make_fake_pnj() -> Node3D:
	var pnj = Node3D.new();
	var cloth = Node3D.new();
	cloth.name = "ClothAnimations";
	for part in [
		["SkinsAnimatedSprite3D", "res://Player/SpriteFrames/Skins_0.tres"],
		["HairsAnimatedSprite3D", "res://Player/SpriteFrames/Hairs_0.tres"],
		["ShirtsAnimatedSprite3D", "res://Player/SpriteFrames/Shirts_0.tres"],
		["PantsAnimatedSprite3D", "res://Player/SpriteFrames/Pants_0.tres"],
	]:
		var spr = AnimatedSprite3D.new();
		spr.name = part[0];
		spr.sprite_frames = load(part[1]);
		spr.animation = "idle";
		cloth.add_child(spr);
	pnj.add_child(cloth);
	add_child(pnj);
	return pnj;

func _test_case(case_name: String, pnj_name: String, ask_text: String, answers: Array, anchor: Vector2, speaker) -> void:
	var dialog: AskDialog = _dialog_scene.instantiate();
	dialog.id = case_name;
	dialog.ask_translation = ask_text;
	dialog.name_translation = pnj_name;
	dialog.answers = answers;
	dialog.global_position = anchor;
	dialog.speaker_alive = speaker;
	add_child(dialog);
	for i in 5:
		await get_tree().process_frame;
	_dump_state(case_name, dialog);
	await RenderingServer.frame_post_draw;
	var img = get_viewport().get_texture().get_image();
	img.save_png("res://tests/out_" + case_name + ".png");
	remove_child(dialog);
	dialog.queue_free();
	await get_tree().process_frame;

func _dump_state(case_name: String, dialog: AskDialog) -> void:
	var ask_container = dialog.get_node("AskContainer");
	var ask_label = dialog.get_node("AskContainer/AskLabel");
	var name_container = dialog.get_node("AskContainer/NameContainer");
	var answers_container = dialog.get_node("AnswersContainer");
	print("--- ", case_name, " ---");
	print("ask_container size=", ask_container.size, " pos=", ask_container.position);
	print("ask_label size=", ask_label.size, " min=", ask_label.get_combined_minimum_size(), " lines=", ask_label.get_line_count());
	print("name_container size=", name_container.size, " pos=", name_container.position);
	print("answers_container size=", answers_container.size, " pos=", answers_container.position);
	for a in answers_container.get_children():
		print("  answer '", a.text, "' size=", a.size, " min=", a.get_combined_minimum_size());
