extends CanvasLayer
class_name UIController

@export var mouse_targets_node_to_exclude: Array[NodePath];

@onready var confirm_modal: Panel = $ConfirmModal;
@onready var stand_setup: StandSetupView = $StandSetup;
@onready var trade_view = $TradeView;
@onready var stand_transaction: StandTransactionView = $StandTransaction;
@onready var modal_container = $ModalContainer;
@onready var game_time_label = $GameTimeCotainer/Label;
@onready var _modal_controller = ModalController.new(modal_container);

var tooltip = preload("res://UI/Tooltip/tooltip.tscn").instantiate();
var _nearest_interactive: Node3D = null;
var _current_mouse_target: Control;
var _health_fill: ColorRect;
var _hunger_fill: ColorRect;
var _debug_menu;
var _death_screen: Control;
var _pause_menu: Control;
var _pause_panel: PanelContainer;
var _pause_blur_mat: ShaderMaterial;
var _pause_tween: Tween;

const GAUGE_W := 110.0;
const GAUGE_H := 14.0;
const GAUGE_INSET := 3.0;

# Called when the node enters the scene tree for the first time.
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS;
	get_viewport().canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST;
	InventoryEvents.dialog_confirm_delete_item.connect(_show_confirm_dialog);
	HudEvents.open_stand_setup.connect(_show_stand_setup_dialog);
	HudEvents.open_stand_transaction.connect(_show_stand_transaction_dialog);
	HudEvents.open_trade_view.connect(_show_trade_view_dialog);
	PlayerEvents.on_nearest_interactive_changed.connect(_show_tooltip_on_interactive);
	for child in get_children():
		if not mouse_targets_node_to_exclude.has(child.get_path()):
			child.mouse_entered.connect(_on_mouse_current_target.bind(child, true));
			child.mouse_exited.connect(_on_mouse_current_target.bind(child, false));
	HudEvents.open_modal.connect(_on_open_modal);
	GameTimeEvents.on_formatted_game_time_changed.connect(_update_game_time_ui);
	PlayerEvents.player_status_changed.connect(_on_player_status_changed);
	$ShortcutBar.pivot_offset = $ShortcutBar.size / 2;
	$ShortcutBar.scale = Vector2(1.5, 1.5);
	var player_node = get_parent().get_node_or_null("Player");
	if player_node != null:
		var preview = preload("res://UI/InventoryView/CharacterPreview.gd").new(player_node, "PLAYER");
		preview.position = Vector2($Inventory.size.x + 8, 0);
		$Inventory.add_child(preview);
		_debug_menu = preload("res://UI/DebugMenu/DebugMenu.gd").new(get_parent(), player_node);
		add_child(_debug_menu);
	_build_gauges();
	_build_death_screen();
	_build_pause_menu();
	PlayerEvents.player_died.connect(func(): _death_screen.visible = true);

func _build_death_screen() -> void:
	_death_screen = Control.new();
	_death_screen.set_anchors_preset(Control.PRESET_FULL_RECT);
	_death_screen.visible = false;
	_death_screen.mouse_filter = Control.MOUSE_FILTER_STOP;
	var bg = ColorRect.new();
	bg.color = Color(0, 0, 0, 0.65);
	bg.set_anchors_preset(Control.PRESET_FULL_RECT);
	_death_screen.add_child(bg);
	var center = CenterContainer.new();
	center.set_anchors_preset(Control.PRESET_FULL_RECT);
	var col = VBoxContainer.new();
	col.alignment = BoxContainer.ALIGNMENT_CENTER;
	col.add_theme_constant_override("separation", 16);
	var title = Label.new();
	title.text = "VOUS ÊTES MORT";
	title.add_theme_font_size_override("font_size", 48);
	title.add_theme_color_override("font_color", Color(0.75, 0.15, 0.15));
	col.add_child(title);
	var btn = Button.new();
	btn.text = "Respawn";
	btn.pressed.connect(_on_respawn);
	col.add_child(btn);
	center.add_child(col);
	_death_screen.add_child(center);
	add_child(_death_screen);

func _on_respawn() -> void:
	_death_screen.visible = false;
	PlayerEvents.respawn.emit();

func _back_to_menu() -> void:
	_hide_pause();
	await get_tree().create_timer(0.35, true, true).timeout;
	get_tree().paused = false;
	get_tree().change_scene_to_file("res://Root.tscn");

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F3:
				_debug_menu.toggle();
			KEY_ESCAPE:
				_toggle_pause();

func _toggle_pause() -> void:
	if _death_screen.visible:
		return;
	if get_tree().paused:
		_hide_pause();
	else:
		_show_pause();

func _show_pause() -> void:
	get_tree().paused = true;
	_pause_menu.visible = true;
	_pause_panel.position.x = -_pause_panel.custom_minimum_size.x;
	_pause_panel.modulate = Color(1, 1, 1, 0);
	_pause_blur_mat.set_shader_parameter("blur", 0.0);
	if _pause_tween:
		_pause_tween.kill();
	_pause_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS);
	_pause_tween.set_parallel();
	_pause_tween.tween_property(_pause_panel, "position:x", 0.0, 0.35);
	_pause_tween.tween_property(_pause_panel, "modulate:a", 1.0, 0.35);
	_pause_tween.tween_property(_pause_blur_mat, "shader_parameter/blur", 3.0, 0.4);

func _hide_pause() -> void:
	if _pause_tween:
		_pause_tween.kill();
	_pause_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS);
	_pause_tween.set_parallel();
	_pause_tween.tween_property(_pause_panel, "position:x", -_pause_panel.custom_minimum_size.x, 0.3);
	_pause_tween.tween_property(_pause_panel, "modulate:a", 0.0, 0.3);
	_pause_tween.tween_property(_pause_blur_mat, "shader_parameter/blur", 0.0, 0.3);
	_pause_tween.chain().tween_callback(func():
		get_tree().paused = false;
		_pause_menu.visible = false;
		_pause_panel.position.x = 0;
		_pause_panel.modulate = Color(1, 1, 1, 1));

func _build_pause_menu() -> void:
	_pause_menu = Control.new();
	_pause_menu.set_anchors_preset(Control.PRESET_FULL_RECT);
	_pause_menu.visible = false;
	_pause_menu.mouse_filter = Control.MOUSE_FILTER_STOP;
	_pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS;
	var blur = ColorRect.new();
	blur.set_anchors_preset(Control.PRESET_FULL_RECT);
	_pause_blur_mat = ShaderMaterial.new();
	_pause_blur_mat.shader = load("res://UI/MainMenu/Blur.gdshader");
	_pause_blur_mat.set_shader_parameter("blur", 3.0);
	blur.material = _pause_blur_mat;
	_pause_menu.add_child(blur);
	var panel = PanelContainer.new();
	_pause_panel = panel;
	panel.set_anchors_preset(Control.PRESET_LEFT_WIDE);
	panel.custom_minimum_size = Vector2(420, 0);
	var panel_style = StyleBoxFlat.new();
	panel_style.bg_color = Color(0, 0, 0, 0.55);
	panel.add_theme_stylebox_override("panel", panel_style);
	var col = VBoxContainer.new();
	col.set_anchors_preset(Control.PRESET_CENTER);
	col.alignment = BoxContainer.ALIGNMENT_CENTER;
	col.add_theme_constant_override("separation", 20);
	var title = Label.new();
	title.text = "PAUSE";
	title.add_theme_font_size_override("font_size", 40);
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75));
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER;
	col.add_child(title);
	var resume_btn = Button.new();
	resume_btn.flat = true;
	resume_btn.text = "Reprendre";
	resume_btn.pressed.connect(_toggle_pause);
	col.add_child(resume_btn);
	var save_btn = Button.new();
	save_btn.flat = true;
	save_btn.text = "Sauvegarder";
	save_btn.pressed.connect(func(): PlayerEvents.save_requested.emit(); save_btn.text = "Sauvegardé !"; await get_tree().create_timer(1.5).timeout; save_btn.text = "Sauvegarder");
	col.add_child(save_btn);
	var menu_btn = Button.new();
	menu_btn.flat = true;
	menu_btn.text = "Menu principal";
	menu_btn.pressed.connect(_back_to_menu);
	col.add_child(menu_btn);
	var quit_btn = Button.new();
	quit_btn.flat = true;
	quit_btn.text = "Quitter";
	quit_btn.pressed.connect(func(): get_tree().paused = false; get_tree().quit());
	col.add_child(quit_btn);
	panel.add_child(col);
	_pause_menu.add_child(panel);
	add_child(_pause_menu);

func _build_gauges() -> void:
	var gauges = Control.new();
	add_child(gauges);
	gauges.position = Vector2(12, 55);
	gauges.scale = Vector2(2.5, 2.5);
	_health_fill = _add_gauge_row(gauges, "res://UI/Sprites/heart.png", Color(0.72, 0.18, 0.18), 0);
	_hunger_fill = _add_gauge_row(gauges, "res://Items/apple.png", Color(0.85, 0.55, 0.2), GAUGE_H + 4);

func _add_gauge_row(parent: Control, icon_path: String, fill_color: Color, row_y: float) -> ColorRect:
	var icon = TextureRect.new();
	icon.texture = load(icon_path);
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED;
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST;
	icon.position = Vector2(0, row_y);
	icon.size = Vector2(GAUGE_H, GAUGE_H);
	parent.add_child(icon);
	var frame = NinePatchRect.new();
	frame.texture = load("res://UI/Modals/modal.png");
	frame.patch_margin_left = 8;
	frame.patch_margin_top = 8;
	frame.patch_margin_right = 8;
	frame.patch_margin_bottom = 8;
	frame.position = Vector2(GAUGE_H + 4, row_y);
	frame.size = Vector2(GAUGE_W, GAUGE_H);
	parent.add_child(frame);
	var fill = ColorRect.new();
	fill.color = fill_color;
	fill.position = Vector2(GAUGE_INSET, GAUGE_INSET);
	fill.size = Vector2(GAUGE_W - GAUGE_INSET * 2, GAUGE_H - GAUGE_INSET * 2);
	frame.add_child(fill);
	return fill;

func _on_player_status_changed(status: Dictionary) -> void:
	_health_fill.size.x = (GAUGE_W - GAUGE_INSET * 2) * status.health.value / status.health.max;
	_hunger_fill.size.x = (GAUGE_W - GAUGE_INSET * 2) * status.hunger.value / status.hunger.max;

func _update_game_time_ui(formatted_game_time: String):
	game_time_label.text = formatted_game_time;

func _on_open_modal(path_node_to_instance: String, params: Dictionary):
	_modal_controller.register_modal(path_node_to_instance, params);

func _show_stand_setup_dialog(container_id: String, screen_position: Vector2) -> void:
	stand_setup.open(container_id, screen_position);

func _show_trade_view_dialog(merchant_container_id: String) -> void:
	trade_view.open(merchant_container_id);

func _show_stand_transaction_dialog(container_id: String, _interract_owner_id: String, screen_position: Vector2) -> void:
	stand_transaction.open(container_id, _interract_owner_id, screen_position);

func _show_confirm_dialog(item):
	var message = tr("DIALOG.CONFIRM_DELETE")+" "+str(item.amount)+" "+tr(item.name)+"(s) ?";
	confirm_modal.open(message, _on_delete_item.bind(item));

func _on_delete_item(_item):
	InventoryEvents.reset_current_item.emit();

func _on_mouse_current_target(target: Control, is_mouse_hover: bool) -> void:
	var mouse_position = target.get_local_mouse_position();
	var stay_in_child = Rect2(Vector2(), target.size).has_point(mouse_position);
	if not is_mouse_hover and stay_in_child:
		return;
	var target_to_emit = target if is_mouse_hover else null;
	_current_mouse_target = target_to_emit;

func get_current_mouse_target() -> Control:
	return _current_mouse_target;

func _show_tooltip_on_interactive(interactive: Node3D) -> void:
	if _nearest_interactive:
		_get_interact_label_container(_nearest_interactive).remove_child(tooltip);
		_nearest_interactive = null;
		stand_transaction.close();
		stand_setup.close();
	if interactive:
		_nearest_interactive = interactive;
		_get_interact_label_container(_nearest_interactive).add_child(tooltip);

func _get_interact_label_container(interactive: Node3D):
	return interactive.get_node(InteractComponent.SCENE_NAME).interactive_label_container;
