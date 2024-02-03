extends InventoryView
class_name StandSetupView

@onready var item_value_label = $VBoxContainer/TextureRect/Value;
@export var MAX_PRICE: int;

func _ready():
	pass

func open(_container_id: String, _position: Vector2) -> void:
	container_id = _container_id;
	_load_container_config();
	var items = MarketController.get_items(container_id);
	_update_items(items);
	global_position = _position;
	visible = true;

func _update_items(slots: Dictionary) -> void:
	super._update_items(slots);
	_update_price();

func _update_price() -> void:
	var item = MarketController.get_first_item(container_id);
	var current_price = MAX_PRICE if not "current_price" in item else item.current_price;
	item_value_label.text = str(current_price);

func _input(_event):
	pass

func _handle_mouse_click(_event: InputEventMouseButton) -> void:
	pass

func close() -> void:
	visible = false;

func _on_minus_button_pressed():
	var item = MarketController.get_first_item(container_id);
	item.current_price = clampi(item.current_price - 1, 0, MAX_PRICE);
	var items = MarketController.get_items(container_id);
	_update_items(items);
	HudEvents.price_item_changed.emit(item);

func _on_plus_button_pressed():
	var item = MarketController.get_first_item(container_id);
	item.current_price = clampi(item.current_price + 1, 0, MAX_PRICE);
	var items = MarketController.get_items(container_id);
	_update_items(items);
	HudEvents.price_item_changed.emit(item);

func _on_close_button_pressed():
	close();
