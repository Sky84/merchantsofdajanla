extends InventoryView
class_name PlayerContainerView

signal update_containers_views;

func _ready():
	container_id = 'player_inventory';
	_load_container_config();
	
func _init_container():
	var items = MarketController.get_items(container_id);
	_update_items(items);
	visible = true;

func _on_slot_pressed(button_index: int, slot: Dictionary, slot_x: int, slot_y: int):
	pass
