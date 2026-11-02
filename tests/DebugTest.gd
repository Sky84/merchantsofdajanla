extends Node

const FakeAlive = preload("res://tests/FakeAlive.gd");
const DebugMenu = preload("res://UI/DebugMenu/DebugMenu.gd");

func _ready() -> void:
	var game_root = Node.new();
	add_child(game_root);
	var player = CharacterBody3D.new();
	player.set_script(FakeAlive);
	player.name = "Player";
	game_root.add_child(player);
	player._owner_id = "player_test";
	var menu = DebugMenu.new(game_root, player);
	add_child(menu);
	menu.toggle();
	print("menu visible=", menu.visible);
	# spawn sawaji via menu
	menu._spawn("res://PNJs/Sawaji/Sawaji.tscn");
	await get_tree().process_frame;
	var sawaji = null;
	for n in get_tree().get_nodes_in_group(Alive.GROUP_NAME):
		if n is HostileController:
			sawaji = n;
	print("sawaji spawned=", sawaji != null, " pos=", sawaji.global_position if sawaji else null);
	# give item
	player.add_child(_make_container());
	ContainersController.register_container("player_inventory", 4, 5, {}, player._owner_id, true);
	menu._item_edit.text = "shirt_basic";
	menu._amount_spin.value = 2;
	menu._give();
	var found = ContainersController.find_item_in_containers([ContainersController.get_container_ids_by_owner_id(player._owner_id)[0]], "shirt_basic");
	print("given item=", found.item.id if not found.is_empty() else "MISSING", " amount=", found.item.amount if not found.is_empty() else 0);
	# inspect fake pnj + drag health to 0
	var pnj = CharacterBody3D.new();
	pnj.set_script(FakeAlive);
	pnj.name = "PNJ_test";
	game_root.add_child(pnj);
	pnj.global_position = Vector3(1, 0, 0);
	await get_tree().process_frame;
	menu._inspect(pnj);
	print("inspecting=", menu._inspected.name, " panel=", menu._inspect_panel.visible);
	pnj.take_damage(30);
	await get_tree().process_frame;
	print("pnj dead=", pnj.is_dead, " inspector closed=", not menu._inspect_panel.visible);
	menu.toggle();
	get_tree().quit();

func _make_container() -> Node:
	return Node.new();
