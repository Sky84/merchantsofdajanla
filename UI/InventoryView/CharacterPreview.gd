extends NinePatchRect

const PREVIEW_SCALE := 2.5;
const SLOT_SIZE := 48.0;
const SLOTS := ["shirt", "pants", "weapon"];
const SLOT_NODES := {"shirt": "ShirtsAnimatedSprite3D", "pants": "PantsAnimatedSprite3D", "weapon": "WeaponsAnimatedSprite3D"};
const SLOT_ICONS := {"shirt": "res://UI/InventoryView/Assets/icon_shirt.png", "pants": "res://UI/InventoryView/Assets/icon_pants.png", "weapon": "res://UI/InventoryView/Assets/icon_sword.png"};
const EMPTY_MODULATE := Color(1, 1, 1, 0.35);
const EQUIPPED_MODULATE := Color(1, 1, 1, 1);

var _player;
var _slot_icons := {};
var _body: Control;

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

	var slot_tex = load("res://Containers/Sprites/SlotItemButton.png");
	for i in SLOTS.size():
		var slot = SLOTS[i];
		var slot_rect = TextureRect.new();
		slot_rect.texture = slot_tex;
		slot_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;
		slot_rect.stretch_mode = TextureRect.STRETCH_SCALE;
		slot_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST;
		slot_rect.position = Vector2(pad, 40 + i * (SLOT_SIZE + 10));
		slot_rect.size = Vector2(SLOT_SIZE, SLOT_SIZE);
		slot_rect.mouse_filter = Control.MOUSE_FILTER_STOP;
		slot_rect.gui_input.connect(_on_slot_gui_input.bind(slot));
		add_child(slot_rect);
		var icon = TextureRect.new();
		icon.texture = load(SLOT_ICONS[slot]);
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE;
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED;
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST;
		icon.set_anchors_preset(Control.PRESET_FULL_RECT);
		icon.offset_left = 8;
		icon.offset_top = 8;
		icon.offset_right = -8;
		icon.offset_bottom = -8;
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE;
		slot_rect.add_child(icon);
		_slot_icons[slot] = icon;
	PlayerEvents.equipment_changed.connect(_refresh_all);
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
	for slot in SLOTS:
		_slot_icons[slot].modulate = EQUIPPED_MODULATE if _player.is_equipped(slot) else EMPTY_MODULATE;

func _on_slot_gui_input(event: InputEvent, slot: String) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return;
	var current = ContainersController.current_item.value;
	if current.is_empty():
		_player.unequip(slot);
	else:
		var item = GameItems._items.get(current.id);
		if item != null and item.get("type") == "Equipment" and item.get("slot") == slot:
			_player.equip(current.id);
			ContainersController.set_current_item("player_inventory", {});
			InventoryEvents.item_in_container_selected.emit({});
	InventoryEvents.visibility_inventory.emit(true);
