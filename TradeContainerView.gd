extends InventoryView
class_name TradeContainerView

signal update_containers_views;

func _ready():
	pass

func _init_container(trade_container_id: String):
	container_id = trade_container_id;
	_load_container_config();
	var items = MarketController.get_items(trade_container_id);
	_update_items(items);
	visible = true;

func _on_slot_pressed(button_index: int, slot: Dictionary, slot_x: int, slot_y: int):
	pass
