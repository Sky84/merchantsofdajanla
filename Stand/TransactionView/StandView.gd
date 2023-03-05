extends InventoryView
class_name StandTransactionView

@onready var item_value_label = $VBoxContainer/TextureRect/Value;

func _ready():
	pass

func open(_container_id: String) -> void:
	container_id = _container_id;
	_load_container_config();
	var items = MarketController.get_items(container_id);
	_update_items(items);
	item_value_label.text = str(get_item().current_price);
	visible = true;

func get_item() -> Dictionary:
	var item = MarketController.get_items(container_id)[0];
	if  not "current_price" in item:
		item.current_price = 999;
	return item;

# We know that going to be called just once because there is only one item for stand
func _update_custom_item(slot_x: int, slot_y: int, slot_instance: SlotButton) -> void:
	if slot_instance.get_child_count() > 0:
		var item_instance: StandItemButton = slot_instance.get_child(0);
		item_instance._set_price(get_item().current_price);

func _input(event):
	pass

func _handle_mouse_click(event: InputEventMouseButton) -> void:
	pass

func close() -> void:
	visible = false;
