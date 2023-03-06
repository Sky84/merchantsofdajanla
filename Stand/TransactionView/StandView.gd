extends InventoryView
class_name StandTransactionView

@onready var item_value_label = $VBoxContainer/TextureRect/Value;
@export var MAX_PRICE: int;

func _ready():
	pass

func open(_container_id: String) -> void:
	container_id = _container_id;
	_load_container_config();
	var items = MarketController.get_items(container_id);
	_update_items(items);
	visible = true;

func _update_items(slots: Dictionary) -> void:
	super._update_items(slots);
	_update_price();

# We know that going to be called just once because there is only one item for stand
func _update_custom_item(slot_x: int, slot_y: int, slot_instance: SlotButton) -> void:
	if slot_instance.get_child_count() > 0:
		var item_instance: StandItemButton = slot_instance.get_child(0);
		item_instance._set_price(MarketController.get_first_item(container_id).current_price);

func _update_price() -> void:
	var item = MarketController.get_first_item(container_id);
	var current_price = MAX_PRICE if not "current_price" in item else item.current_price;
	item_value_label.text = str(current_price);

func _input(event):
	pass

func _handle_mouse_click(event: InputEventMouseButton) -> void:
	pass

func close() -> void:
	visible = false;

func _on_minus_button_pressed():
	var item = MarketController.get_first_item(container_id);
	item.current_price = clampi(item.current_price - 1, 0, MAX_PRICE);
	var items = MarketController.get_items(container_id);
	_update_items(items);

func _on_plus_button_pressed():
	var item = MarketController.get_first_item(container_id);
	item.current_price = clampi(item.current_price + 1, 0, MAX_PRICE);
	var items = MarketController.get_items(container_id);
	_update_items(items);
