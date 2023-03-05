extends Node

func get_items(container_id: String) -> Dictionary:
	var slots = ContainersController.get_container_data(container_id).duplicate(true);
	for x in slots:
		for y in slots[x]:
			var item = slots[x][y];
			if item:
				item.current_price = get_current_price(item.id);
	return slots;

func get_current_price(item_id: String):
	return GameItems.get_item(item_id).base_price;
