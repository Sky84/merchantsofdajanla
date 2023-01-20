extends Panel

@export var container_id: String;
@export var _item_button_scene: PackedScene;
@export var _item_slot_button_scene: PackedScene;
@export var rows: int;

@onready var hover_texture = $HoverTexture;
@onready var _items_container:GridContainer = get_node("MarginContainer/ItemsContainerView");
@onready var _total_items = rows*_items_container.columns;
@onready var info_panel = %InfoPanel;

var slots: Dictionary = {};
var _items = {};

var item_with_gap = (32+10);

var _current_item = null;

# Called when the node enters the scene tree for the first time.
func _ready():
	if container_id == null:
		printerr("container_id is not set");
	if rows == 0:
		printerr("rows is not set");
	InventoryEvents.container_data_changed.connect(_on_data_changed);
	InventoryEvents.reset_current_item.connect(_on_reset_current_item);
	InventoryEvents.visibility_inventory.connect(_on_visibility_inventory);

func _on_visibility_inventory(value: bool):
	visible = value;
	info_panel.visible = value;

func _on_reset_current_item():
	_current_item = null;
	InventoryEvents.emit_signal("item_in_container_selected", {});

func _on_data_changed(__container_id:String, __items:Dictionary):
	if container_id != __container_id:
		return;
	_items = __items;
	if slots.keys().size() == 0:
		init_slots();
	_update_items();

func init_slots():
	var items_to_place = _items.duplicate(true);
	for x in _items_container.columns:
		slots[x] = {};
		for y in rows:
			if items_to_place.size() > 0:
				var item_key = items_to_place.keys().front();
				slots[x][y] = items_to_place[item_key];
				items_to_place.erase(item_key)
			else:
				slots[x][y] = {};

func _update_items():
	var childs = _items_container.get_children();
	for child in childs:
		child.queue_free()
		_items_container.remove_child(child);
	for x in slots:
		for y in slots[x]:
			var slot = slots[x][y];
			var slot_instance = _item_slot_button_scene.instantiate();
			_items_container.add_child(slot_instance);
			slot_instance.pressed_with.connect(_on_slot_pressed.bind(slot, x, y));
			if !slot.is_empty():
				var item_instance = _item_button_scene.instantiate();
				slot_instance.add_child(item_instance);
				item_instance.init_item(slot);

func _on_slot_pressed(button_index: int, slot: Dictionary, slot_x: int, slot_y: int):
	var is_pick_one = button_index == MOUSE_BUTTON_RIGHT;
	var slot_empty = slot.is_empty();
	if _current_item == null: # handling first click on slot
		if !slot_empty:
			if is_pick_one: # handling player want just to pick one item
				slots[slot_x][slot_y] = _pick_one_from(slots[slot_x][slot_y]);
				_current_item = _get_one_item_of(slot);
			else:
				_current_item = slot;
				slots[slot_x][slot_y] = {};
	else: # handling click with current item (Ex. Player click to move or add one more to current)
		if !slot_empty: # handling on occupied slot
			if is_pick_one && slot.id == _current_item.id: # add one more to current_item if there are the same
				slots[slot_x][slot_y] = _pick_one_from(slots[slot_x][slot_y]);
				_current_item.amount = _current_item.amount + 1;
			elif !is_pick_one: # just placing the current_item and taking the item slot
				if slot.id == _current_item.id:
					slots[slot_x][slot_y].amount = slots[slot_x][slot_y].amount + _current_item.amount;
					_current_item = null;
				else:
					slots[slot_x][slot_y] = _current_item;
					_current_item = slot;
		else: #handling placing all or just one
			if is_pick_one:
				slots[slot_x][slot_y] = _get_one_item_of(_current_item);
				var item_alone: Dictionary = _pick_one_from(_current_item);
				_current_item = null if item_alone.is_empty() else item_alone;
			else:
				slots[slot_x][slot_y] = _current_item;
				_current_item = null;
	_update_items();
	var mouse_item = {} if _current_item == null else _current_item;
	InventoryEvents.emit_signal("item_in_container_selected", mouse_item);

func _get_one_item_of(slot: Dictionary):
	var next_current = slot.duplicate(true);
	next_current.amount = 1;
	return next_current;

func _pick_one_from(slot: Dictionary):
	var slot_amount = slot.amount;
	if slot_amount > 1:
		slot.amount = slot_amount - 1;
	else:
		slot = {};
	return slot;

func _input(event):
	if event is InputEventMouseButton and _current_item:
		var click_outside = !get_rect().has_point(event.position); 
		if (click_outside and !event.is_pressed()):
			InventoryEvents.dialog_confirm_delete_item.emit(_current_item);
	elif event is InputEventMouseMotion and get_rect().has_point(event.position):
		var local_mouse_position = Vector2(_items_container.get_local_mouse_position() / item_with_gap).floor();
		local_mouse_position.x = clamp(local_mouse_position.x, 0, _items_container.columns-1);
		local_mouse_position.y = clamp(local_mouse_position.y, 0, rows-1);
		var hover_texture_position = (local_mouse_position * item_with_gap) - Vector2(1,0);
		hover_texture.position = _items_container.position + hover_texture_position;
