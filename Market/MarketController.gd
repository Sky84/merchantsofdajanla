extends Node

func get_items(container_id: String) -> Dictionary:
	var slots = ContainersController.get_container_data(container_id);
	for x in slots:
		for y in slots[x]:
			var item = slots[x][y];
			if item:
				item.current_price = get_current_price(item);
	return slots;

func get_current_price(item: Dictionary):
	var current_price = item.base_price;
	if 'current_price' in item:
		current_price = item.current_price;
	return current_price;
