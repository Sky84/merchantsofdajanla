extends Node

var _containers: Dictionary = {};

var current_item: Dictionary = {
	"container_id": null,
	"value": {}
};

func register_container(container_id: String, rows: int, columns: int, items: Dictionary, container_owner: String = "", _is_main_container_for_owner: bool = false) -> void:
	_containers[container_id] = {
		"container_owner": container_owner,
		"is_main_container": _is_main_container_for_owner,
		"slots": _init_slots(rows, columns, items),
		"rows": rows,
		"columns": columns
	};

func _init_slots(rows: int, columns: int, _items: Dictionary) -> Dictionary:
	var items_to_place = _items.duplicate(true);
	var slots = {};
	for x in columns:
		slots[x] = {};
		for y in rows:
			if items_to_place.size() > 0:
				var item_key = items_to_place.keys().front();
				slots[x][y] = items_to_place[item_key];
				items_to_place.erase(item_key)
			else:
				slots[x][y] = {};
	return slots;

func update(container_id: String, _items: Dictionary) -> void:
	var slots = _containers[container_id].slots;
	for item_id in _items:
		for x in slots:
			for y in slots[x]:
				var slot = slots[x][y];
				slot = _items[item_id];
	InventoryEvents.container_data_changed.emit(container_id);

func set_current_item(container_id: String, item: Dictionary):
	current_item = {
		"container_id": container_id,
		"value": item
	};

func get_container_ids_by_owner_id(owner_id: String) -> Array[String]:
	var container_ids: Array[String] = [];
	for container_id in _containers:
		if _containers[container_id].container_owner == owner_id:
			container_ids.append(container_id);
	return container_ids;

func get_main_container_with_empty_slot(container_ids: Array[String]) -> String:
	for container_id in container_ids:
		if _containers[container_id].is_main_container:
			return container_id;
	return '';

func find_item_in_containers(container_ids: Array[String], item_id: String) -> Dictionary:
	var items = container_ids.duplicate().map(
		func(container_id):
			var slots = get_container_data(container_id);
			for x in slots:
				for y in slots[x]:
					var slot = slots[x][y];
					if 'id' in slot and slot.id == item_id:
						return {'container_id': container_id, 'item': slot};
			return {};
			);
	items.sort_custom(func(a, b): return !a.is_empty() and b.is_empty());
	return items[0];

func add_item(container_ids: Array[String], item_id: String, amount_to_add: int):
	var item_data = find_item_in_containers(container_ids, item_id);
	if not item_data.is_empty():
		item_data.item.amount += amount_to_add;
	else:
		_create_in_empty_slot(container_ids, item_id, amount_to_add);

func remove_item(container_ids: Array[String], item_id: String, amount_to_remove: int):
	var item_data = find_item_in_containers(container_ids, item_id);
	if not item_data.is_empty():
		item_data.item.amount -= amount_to_remove;
		if item_data.item.amount < 1:
			_erase_item_in_container(item_data.container_id, item_id);

# erase completely the first item who match with item_id in containers
func _erase_item_in_container(container_id: String, item_id: String) -> void:
	var slots = get_container_data(container_id);
	for x in slots:
		for y in slots[x]:
			var slot = slots[x][y];
			if not slot.is_empty() and slot.id == item_id:
				slots[x][y] = {};
				return;

# create an item from scratch in an empty slot
func _create_in_empty_slot(container_ids: Array[String], item_id: String, amount_to_add: int) -> void:
	for container_id in container_ids:
		var slots = get_container_data(container_id);
		for x in slots:
			for y in slots[x]:
				var slot = slots[x][y];
				if slot.is_empty():
					slots[x][y] = GameItems.get_item(item_id);
					slots[x][y].amount = amount_to_add;
					return;

func get_container_data(container_id: String) -> Dictionary:
	return _containers[container_id].slots;

func get_container_config(container_id: String) -> Dictionary:
	var data = _containers[container_id].duplicate(true);
	data.erase('slots');
	return data;
