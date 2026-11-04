extends NinePatchRect

const PREVIEW_SCALE := 2.5;
const SLOT_SIZE := 48.0;
const SLOTS := ["shirt", "pants", "weapon"];
const SLOT_ICONS := {"shirt": "res://UI/InventoryView/Assets/icon_shirt.png", "pants": "res://UI/InventoryView/Assets/icon_pants.png", "weapon": "res://UI/InventoryView/Assets/icon_sword.png"};
const SLOT_BUTTON_SCENE := preload("res://Containers/SlotItemButton/SlotItemButton.tscn");
const ITEM_BUTTON_SCENE := preload("res://Containers/ItemButton/ItemButton.tscn");
const EMPTY_MODULATE := Color(1, 1, 1, 0.35);
const EQUIPPED_MODULATE := Color(1, 1, 1, 1);

var _player;
var _slot_icons := {};
var _slot_buttons := {};
var _body: Control;
var _equipment_cid := "";

func _init(player, player_name := "PLAYER") -> void:
	_player = player;
	texture = load("res://Containers/Sprites/background_Inventory.png");
	for margin in ["patch_margin_left", "patch_margin_top", "patch_margin_right", "patch_margin_bottom"]:
		set(margin, 8);
	var body_w = 32 * PREVIEW_SCALE;
	var body_h = 64 * PREVIEW_SCALE;
	var pad = 18.0;
	custom_minimum_size = Vector2(pad * 3 + body_w + SLOT_SIZE, body_h + 70.0);
	size = custom_minimum_size;

	var name_label = Label.new();
	name_label.text = player_name;
	name_label.add_theme_color_override("font_color", Color(0.35, 0.22, 0.12));
	name_label.position = Vector2(pad + SLOT_SIZE + pad, 14);
	add_child(name_label);

	_body = Control.new();
	_body.position = Vector2(pad + SLOT_SIZE + pad, 40);
	_body.custom_minimum_size = Vector2(body_w, body_h);
	add_child(_body);
	_refresh_body();

	for i in SLOTS.size():
		var slot = SLOTS[i];
		var slot_btn = SLOT_BUTTON_SCENE.instantiate();
		slot_btn.position = Vector2(pad, 40 + i * (SLOT_SIZE + 10));
		slot_btn.scale = Vector2(SLOT_SIZE / 32.0, SLOT_SIZE / 32.0);
		slot_btn.pressed_with.connect(_on_equip_slot_pressed.bind(i));
		add_child(slot_btn);
		var icon = TextureRect.new();
		icon.texture = load(SLOT_ICONS[slot]);
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED;
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST;
		icon.set_anchors_preset(Control.PRESET_FULL_RECT);
		icon.offset_left = 6;
		icon.offset_top = 6;
		icon.offset_right = -6;
		icon.offset_bottom = -6;
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE;
		slot_btn.add_child(icon);
		_slot_icons[slot] = icon;
		_slot_buttons[slot] = slot_btn;
	_equipment_cid = "equipment_" + _player._owner_id;
	InventoryEvents.container_data_changed.connect(_on_container_data_changed);
	PlayerEvents.equipment_changed.connect(_refresh_all);

func _ready() -> void:
	_refresh_all();

func _refresh_all() -> void:
	_refresh_body();
	_refresh_slots();

func _refresh_body() -> void:
	for child in _body.get_children():
		child.queue_free();
	var bg = ColorRect.new();
	bg.color = Color(0.22, 0.15, 0.1, 0.55);
	bg.position = Vector2(-12, -10);
	bg.size = _body.custom_minimum_size + Vector2(24, 30);
	_body.add_child(bg);
	var shadow = TextureRect.new();
	shadow.texture = load("res://UI/InventoryView/Assets/shadow.png");
	shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;
	shadow.stretch_mode = TextureRect.STRETCH_SCALE;
	shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST;
	shadow.position = Vector2(-16, _body.custom_minimum_size.y - 24);
	shadow.size = Vector2(_body.custom_minimum_size.x + 32, 28);
	_body.add_child(shadow);
	var cloth = _player.get_node_or_null("ClothAnimations");
	if cloth == null:
		return;
	for part_name in ["SkinsAnimatedSprite3D", "PantsAnimatedSprite3D", "ShirtsAnimatedSprite3D", "HairsAnimatedSprite3D", "WeaponsAnimatedSprite3D"]:
		var spr = cloth.get_node_or_null(part_name);
		if spr == null or spr.sprite_frames == null or not spr.visible:
			continue;
		var anim = spr.animation if spr.animation != &"" else &"idle";
		var tex = spr.sprite_frames.get_frame_texture(anim, spr.frame);
		if tex == null:
			continue;
		var tex_rect = TextureRect.new();
		tex_rect.texture = tex;
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;
		tex_rect.stretch_mode = TextureRect.STRETCH_SCALE;
		tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST;
		tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT);
		_body.add_child(tex_rect);

func _refresh_slots() -> void:
	var has_container = ContainersController.containers.has(_equipment_cid);
	var slots = ContainersController.get_container_data(_equipment_cid) if has_container else {};
	for i in SLOTS.size():
		var slot = SLOTS[i];
		var btn = _slot_buttons[slot];
		var cell: Dictionary = slots[i][0] if has_container else {};
		var old = btn.get_node_or_null("EquippedItem");
		if old:
			btn.remove_child(old);
			old.queue_free();
		_slot_icons[slot].visible = cell.is_empty();
		if cell.is_empty():
			_slot_icons[slot].modulate = EQUIPPED_MODULATE if _player.is_equipped(slot) else EMPTY_MODULATE;
		else:
			var item_btn = ITEM_BUTTON_SCENE.instantiate();
			item_btn.name = "EquippedItem";
			item_btn.set_anchors_preset(Control.PRESET_FULL_RECT);
			btn.add_child(item_btn);
			item_btn.init_item(cell, false);
			var amount = item_btn.get_node_or_null("Amount");
			if amount:
				amount.visible = false;

func _on_container_data_changed(cid: String) -> void:
	if cid == _equipment_cid:
		_refresh_slots();

func _on_equip_slot_pressed(_button_index: int, x: int) -> void:
	if _equipment_cid.is_empty() or not ContainersController.containers.has(_equipment_cid):
		return;
	var slots = ContainersController.get_container_data(_equipment_cid);
	var cell = slots[x][0];
	var current = ContainersController.current_item.value.duplicate(true);
	if current.is_empty():
		if cell.is_empty():
			return;
		current = cell;
		slots[x][0] = {};
	else:
		var data = GameItems._items.get(current.id);
		if data == null or data.get("type") != "Equipment" or data.get("slot") != SLOTS[x]:
			return;
		var previous = cell;
		slots[x][0] = current;
		current = previous;
	InventoryEvents.item_in_container_selected.emit(current);
	ContainersController.set_current_item(_equipment_cid, current);
	InventoryEvents.container_data_changed.emit(_equipment_cid);
