extends InventoryView
class_name PlayerContainerView

signal update_containers_views;

var _trade_container_id: String;

func _ready():
	ContainersController.on_registered_container.connect(on_registered_container);

func on_registered_container(registered_container_id: String) -> void:
	if registered_container_id == container_id:
		_load_container_config();
		ContainersController.on_registered_container.disconnect(on_registered_container);
	
func _init_container(trade_container_id: String):
	_trade_container_id = trade_container_id;
	var items = MarketController.get_items(container_id);
	_update_items(items);
	visible = true;

func _on_slot_pressed(button_index: int, slot: Dictionary, slot_x: int, slot_y: int):
	if not slot.is_empty():
		if slot.id == MarketController.MONEY_ITEM_ID:
			NotificationEvents.notify.emit(NotificationEvents.NotificationType.ERROR, 'MARKET.CANT_BUY_MONEY');
			return;
		ContainersController.add_item([_trade_container_id], slot.id, 1);
		ContainersController.remove_item([container_id], slot.id, 1);
	update_containers_views.emit();

func on_close():
	pass
