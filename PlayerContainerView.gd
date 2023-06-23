extends InventoryView
class_name PlayerContainerView

func _ready():
	container_id = 'player_inventory';
	_load_container_config();
	
func _init_container():
	var items = MarketController.get_items(container_id);
	_update_items(items);
	visible = true;
