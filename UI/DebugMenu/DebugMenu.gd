extends Control
class_name DebugMenu

const SCENES := {
	"Sawaji": "res://PNJs/Sawaji/Sawaji.tscn",
	"Citoyen": "res://PNJs/Citizen/Citizen.tscn",
	"Marchand": "res://PNJs/Merchant/Merchant.tscn",
	"Coffre": "res://Stand/chest.tscn",
};
const HIT_DIST := 80.0;
const BAR_SIZE := Vector2(140, 12);
const GAUGE_COLORS := {"health": Color(0.72, 0.18, 0.18), "hunger": Color(0.85, 0.55, 0.2)};

var _game;
var _player;
var _menu_panel: PanelContainer;
var _inspect_panel: PanelContainer;
var _inspected = null;
var _inspect_name: Label;
var _stat_bars := {};
var _stat_labels := {};
var _item_edit: LineEdit;
var _amount_spin: SpinBox;

func _init(game_root: Node, player_node) -> void:
	_game = game_root;
	_player = player_node;
	visible = false;
	_menu_panel = _build_menu();
	add_child(_menu_panel);
	_inspect_panel = _build_inspector();
	_inspect_panel.visible = false;
	add_child(_inspect_panel);

func toggle() -> void:
	visible = not visible;
	if not visible:
		_close_inspect();

func _build_menu() -> PanelContainer:
	var panel = _make_panel(Vector2(10, 140));
	var col = VBoxContainer.new();
	col.add_theme_constant_override("separation", 6);
	var title = Label.new();
	title.text = "DEBUG";
	col.add_child(title);
	var spawn_row = HBoxContainer.new();
	spawn_row.add_theme_constant_override("separation", 4);
	for scene_name in SCENES:
		var btn = Button.new();
		btn.text = scene_name;
		btn.pressed.connect(_spawn.bind(SCENES[scene_name]));
		spawn_row.add_child(btn);
	col.add_child(spawn_row);
	var give_row = HBoxContainer.new();
	give_row.add_theme_constant_override("separation", 4);
	_item_edit = LineEdit.new();
	_item_edit.placeholder_text = "item_id";
	_item_edit.custom_minimum_size = Vector2(110, 0);
	_amount_spin = SpinBox.new();
	_amount_spin.min_value = 1;
	_amount_spin.max_value = 99;
	_amount_spin.value = 1;
	var give_btn = Button.new();
	give_btn.text = "Give";
	give_btn.pressed.connect(_give);
	var reset_btn = Button.new();
	reset_btn.text = "ResetSave";
	reset_btn.pressed.connect(func(): DirAccess.remove_absolute("user://savegame.json"));
	give_row.add_child(_item_edit);
	give_row.add_child(_amount_spin);
	give_row.add_child(give_btn);
	give_row.add_child(reset_btn);
	col.add_child(give_row);
	panel.add_child(col);
	return panel;

func _build_inspector() -> PanelContainer:
	var panel = _make_panel(Vector2.ZERO);
	var col = VBoxContainer.new();
	_inspect_name = Label.new();
	col.add_child(_inspect_name);
	for key in GAUGE_COLORS:
		var row = HBoxContainer.new();
		var label = Label.new();
		label.text = key;
		label.custom_minimum_size = Vector2(50, 0);
		_stat_labels[key] = Label.new();
		var bar_bg = ColorRect.new();
		bar_bg.color = Color(0.1, 0.08, 0.08, 0.9);
		bar_bg.custom_minimum_size = BAR_SIZE;
		bar_bg.mouse_filter = Control.MOUSE_FILTER_STOP;
		var fill = ColorRect.new();
		fill.color = GAUGE_COLORS[key];
		fill.position = Vector2(1, 1);
		fill.size = BAR_SIZE - Vector2(2, 2);
		bar_bg.add_child(fill);
		bar_bg.gui_input.connect(_on_bar_gui_input.bind(key));
		_stat_bars[key] = fill;
		row.add_child(label);
		row.add_child(bar_bg);
		row.add_child(_stat_labels[key]);
		col.add_child(row);
	var kill_btn = Button.new();
	kill_btn.text = "Kill";
	kill_btn.pressed.connect(_kill_inspected);
	col.add_child(kill_btn);
	panel.add_child(col);
	return panel;

func _make_panel(pos: Vector2) -> PanelContainer:
	var panel = PanelContainer.new();
	panel.position = pos;
	var style = StyleBoxFlat.new();
	style.bg_color = Color(0.12, 0.08, 0.08, 0.92);
	style.border_color = Color(0.55, 0.3, 0.2);
	style.border_width_left = 2;
	style.border_width_top = 2;
	style.border_width_right = 2;
	style.border_width_bottom = 2;
	style.corner_radius_top_left = 4;
	style.corner_radius_top_right = 4;
	style.corner_radius_bottom_left = 4;
	style.corner_radius_bottom_right = 4;
	style.content_margin_left = 8;
	style.content_margin_top = 8;
	style.content_margin_right = 8;
	style.content_margin_bottom = 8;
	panel.add_theme_stylebox_override("panel", style);
	return panel;

func _spawn(scene_path: String) -> void:
	var node = load(scene_path).instantiate();
	_game.add_child(node);
	if node is Node3D:
		node.global_position = _player.global_position + Vector3(2.5, 0, 0);

func _give() -> void:
	var item_id = _item_edit.text.strip_edges();
	if not GameItems._items.has(item_id):
		return;
	var container_ids = ContainersController.get_container_ids_by_owner_id(_player._owner_id);
	ContainersController.add_item(container_ids, item_id, int(_amount_spin.value));
	for cid in container_ids:
		InventoryEvents.container_data_changed.emit(cid);

func _input(event: InputEvent) -> void:
	if not visible or not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return;
	if _menu_panel.get_global_rect().has_point(event.position) or _inspect_panel.get_global_rect().has_point(event.position):
		return;
	var alive = _alive_at_screen(event.position);
	if alive:
		_inspect(alive);
	else:
		_close_inspect();

func _alive_at_screen(screen_pos: Vector2):
	var cam = get_viewport().get_camera_3d();
	if cam == null:
		return null;
	var best = null;
	var best_dist = HIT_DIST;
	for alive in get_tree().get_nodes_in_group(Alive.GROUP_NAME):
		if not is_instance_valid(alive) or alive.get("is_dead"):
			continue;
		var dist = cam.unproject_position(alive.global_position).distance_to(screen_pos);
		if dist < best_dist:
			best = alive;
			best_dist = dist;
	return best;

func _inspect(alive) -> void:
	_inspected = alive;
	_inspect_name.text = "%s (%s)" % [alive.name, alive.get("species_id")];
	_inspect_panel.visible = true;
	_update_inspector();

func _close_inspect() -> void:
	_inspected = null;
	_inspect_panel.visible = false;

func _process(_delta: float) -> void:
	if _inspected == null:
		return;
	if not is_instance_valid(_inspected) or _inspected.get("is_dead"):
		_close_inspect();
		return;
	_update_inspector();

func _update_inspector() -> void:
	var cam = get_viewport().get_camera_3d();
	if cam:
		_inspect_panel.position = cam.unproject_position(_inspected.global_position + Vector3(0, 2.0, 0)) + Vector2(10, 0);
	for key in _stat_bars:
		var stat = _inspected.alive_status.get(key);
		if stat == null:
			continue;
		var frac = stat.value / float(stat.max);
		_stat_bars[key].size.x = (BAR_SIZE.x - 2) * frac;
		_stat_labels[key].text = str(stat.value);

func _on_bar_gui_input(event: InputEvent, key: String) -> void:
	var pressed = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT;
	var dragging = event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT;
	if pressed or dragging:
		var stat = _inspected.alive_status.get(key);
		if stat == null:
			return;
		stat.value = int(round(clamp(event.position.x / BAR_SIZE.x, 0.0, 1.0) * stat.max));
		if key == "health" and stat.value <= 0 and _inspected.has_method("die"):
			_inspected.die();
		elif _inspected == _player:
			PlayerEvents.player_status_changed.emit(_player.alive_status);

func _kill_inspected() -> void:
	if _inspected != null and _inspected.has_method("die"):
		_inspected.die();
		_close_inspect();
