extends Node

var _containers: Dictionary = {};

var current_item: Dictionary = {
	"container_id": null,
	"value": {}
};

func register_container(container_id: String, rows: int, columns: int, items: Dictionary, container_owner: String = "") -> void:
	_containers[container_id] = {
		"container_owner": container_owner,
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

func get_container_data(container_id: String) -> Dictionary:
	return _containers[container_id].slots;

func get_container_config(container_id: String) -> Dictionary:
	var data = _containers[container_id].duplicate(true);
	data.erase('slots');
	return data;
