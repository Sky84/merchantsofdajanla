extends Node

const MONEY_ITEM_ID: String = 'money';

func get_items(container_id: String) -> Dictionary:
	var slots = ContainersController.get_container_data(container_id);
	for x in slots:
		for y in slots[x]:
			var item = slots[x][y];
			if item:
				item.current_price = get_current_price(item);
	return slots;

func trade(seller_container_id: String, seller_item_id: String, seller_amount_to_buy: int, _current_seller_id: String, _current_buyer_id: String) -> void:
	var item = ContainersController.find_item_in_containers([seller_container_id], seller_item_id).item;
	var seller_container_ids = ContainersController.get_container_ids_by_owner_id(_current_seller_id);
	var buyer_container_ids = ContainersController.get_container_ids_by_owner_id(_current_buyer_id);
	if !item.is_empty():
		var main_seller_container_id = ContainersController.get_main_container_with_empty_slot(seller_container_ids);
		if main_seller_container_id.is_empty():
			NotificationEvents.notify.emit(NotificationEvents.NotificationType.ERROR, 'MARKET.TRADE_FAIL.INVENTORY_FULL');
			return;
		var item_total_price = item.current_price * seller_amount_to_buy;
		ContainersController.remove_item([seller_container_id], seller_item_id, seller_amount_to_buy);
		ContainersController.add_item(buyer_container_ids, seller_item_id, seller_amount_to_buy);
		ContainersController.remove_item(buyer_container_ids, MONEY_ITEM_ID, item_total_price);
		ContainersController.add_item([main_seller_container_id], MONEY_ITEM_ID, item_total_price);

func get_current_price(item: Dictionary):
	var current_price = item.base_price;
	if 'current_price' in item:
		current_price = item.current_price;
	return current_price;

func get_first_item(container_id: String) -> Dictionary:
	var item = MarketController.get_items(container_id)[0][0];
	return item;
