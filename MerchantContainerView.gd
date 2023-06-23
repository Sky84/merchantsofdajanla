extends InventoryView
class_name MerchantContainerView

func _ready():
	pass

func _init_container(merchant_container_id: String):
	container_id = merchant_container_id;
	_load_container_config();
	var items = MarketController.get_items(merchant_container_id);
	_update_items(items);
	visible = true;
