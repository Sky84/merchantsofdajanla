extends Panel
class_name InventoryView

@export var container_id: String;
@export var _show_panel_info: bool = true;
@export var _item_button_scene: PackedScene;
@export var _item_slot_button_scene: PackedScene;
@export var rows: int;
@export var gap_hover_selector: int;
@export var offset_hover_selector: Vector2;

@onready var hover_texture = $HoverTexture;
@onready var _items_container: GridContainer = get_node("MarginContainer/ItemsContainerView");
@onready var info_panel = %InfoPanel;
@onready var item_with_gap = (32+gap_hover_selector);

var slots: Dictionary = {};
var _items = {};

var _current_item = null;
var inventory_visible: bool = false;
var mouse_outside: bool = false;

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
	inventory_visible = value;
	check_mouse_outside();

func _on_reset_current_item():
	_current_item = null;
	InventoryEvents.item_in_container_selected.emit({});

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
				item_instance.init_item(slot, _show_panel_info);

func _on_slot_pressed(button_index: int, slot: Dictionary, slot_x: int, slot_y: int):
	var is_pick_one = button_index == MOUSE_BUTTON_RIGHT;
	var slot_empty = slot.is_empty();
	if _current_item == null: # handling first click on slot
		if !slot_empty:
			if is_pick_one: # handling player want just to pick one item
				slots[slot_x][slot_y] = InventoryUtils._pick_one_from(slots[slot_x][slot_y]);
				_current_item = InventoryUtils._get_one_item_of(slot);
			else:
				_current_item = slot;
				slots[slot_x][slot_y] = {};
	else: # handling click with current item (Ex. Player click to move or add one more to current)
		if !slot_empty: # handling on occupied slot
			if is_pick_one && slot.id == _current_item.id: # add one more to current_item if there are the same
				slots[slot_x][slot_y] = InventoryUtils._pick_one_from(slots[slot_x][slot_y]);
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
				slots[slot_x][slot_y] = InventoryUtils._get_one_item_of(_current_item);
				var item_alone: Dictionary = InventoryUtils._pick_one_from(_current_item);
				_current_item = null if item_alone.is_empty() else item_alone;
			else:
				slots[slot_x][slot_y] = _current_item;
				_current_item = null;
	_update_items();
	var mouse_item = {} if _current_item == null else _current_item;
	InventoryEvents.item_in_container_selected.emit(mouse_item);

func check_mouse_outside() -> void:
	if not inventory_visible:
		InventoryEvents.mouse_outside.emit(true);
	else:
		var mouse_position = get_global_mouse_position();
		var is_outside = !get_rect().has_point(mouse_position);
		if mouse_outside != is_outside:
			mouse_outside = is_outside;
		InventoryEvents.mouse_outside.emit(mouse_outside);

func _input(event):
	if event is InputEventMouse:
		check_mouse_outside();
		if event is InputEventMouseMotion:
			if !mouse_outside:
				var local_mouse_position = Vector2(_items_container.get_local_mouse_position() / item_with_gap).floor();
				local_mouse_position.x = clamp(local_mouse_position.x, 0, _items_container.columns-1);
				local_mouse_position.y = clamp(local_mouse_position.y, 0, rows-1);
				var hover_texture_position = (local_mouse_position * item_with_gap) - Vector2(1,0);
				hover_texture.position = _items_container.position + hover_texture_position;
		if event is InputEventMouseButton and _current_item:
			_handle_mouse_click(event);
				
func _handle_mouse_click(event: InputEventMouseButton) -> void:
	var mouse_left_released = !event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT;
	var mouse_right_released = !event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT;
	if mouse_outside:
		if mouse_left_released:
			_handle_delete_item();
		if mouse_right_released:
			_handle_place_item();

func _handle_delete_item() -> void:
	InventoryEvents.dialog_confirm_delete_item.emit(_current_item);
	
func _handle_place_item() -> void:
	_current_item = InventoryUtils._pick_one_from(_current_item);
	InventoryEvents.place_item_on_map.emit(_current_item);
	if _current_item.is_empty():
		_on_reset_current_item();
