extends InventoryView
class_name MerchantContainerView

var _trade_container_id: String;

signal update_containers_views;

func _ready():
	pass

func _init_container(merchant_container_id: String, trade_container_id: String):
	container_id = merchant_container_id;
	_load_container_config();
	var items = MarketController.get_items(merchant_container_id);
	_update_items(items);
	visible = true;
	_trade_container_id = trade_container_id;

func _on_slot_pressed(button_index: int, slot: Dictionary, slot_x: int, slot_y: int):
	if not slot.is_empty():
		ContainersController.add_item([_trade_container_id], slot.id, 1);
		update_containers_views.emit();
