extends Node

var _items := {};

var _game_items_json_path = 'Items.json';

# Called when the node enters the scene tree for the first time.
func _ready():
	_items = JsonResourceLoader.load_json(_game_items_json_path);

func get_start_items(start_items_path: String):
	var start_items = JsonResourceLoader.load_json(start_items_path);
	var start_items_keys = start_items.keys();
	
	for key in start_items_keys:
		start_items[key] = _merge_dictionary(get_item(key), start_items[key]);
	return start_items;

func get_item(item_id: String):
	var item = _items.get(item_id);
	if item.has('prototype'):
		item = _merge_dictionary(get_item(item.prototype), item);
	item.id = item_id;
	return item;

func get_items_by_subtype(item_subtype: String) -> Array[Dictionary]:
	var items: Array[Dictionary] = [];
	for item_id in _items:
		var complete_item = get_item(item_id);
		if 'subtype' in complete_item and complete_item.subtype == item_subtype:
			items.append(complete_item);
	return items;

func is_tool_or_weapon(item: Dictionary) -> bool:
	return item.has('type') and item.type == 'Tool';

func is_consomable(item: Dictionary) -> bool:
	return item.has('type') and item.type == 'Consomable';

func _merge_dictionary(target: Dictionary, source: Dictionary):
	var __target = target.duplicate(true);
	for key in source:                           # go via all keys in source
		if __target.has(key):                    # we found matching key in __target
			var target_value = __target[key]     # get value 
			var source_value = source[key]       # get value in the source dict           
			if typeof(target_value) == TYPE_DICTIONARY:       
				if typeof(source_value) == TYPE_DICTIONARY: 
					_merge_dictionary(target_value, source_value)  
				else:
					__target[key] = source_value # override the __target value
			else:
				__target[key] = source_value     # add to dictionary 
		else:
			__target[key] = source[key]          # just add value to the __target
	return __target;
