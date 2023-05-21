# This class intends to deal with map items instances
# It can create / delete objects on the map
extends GridMap
class_name GridMapController

@onready var _map_items = $MapItems;
var _map_objects := {};

func _ready():
	GridMapEvents.place_item_at.connect(_place_item_at);
	for child in _map_items.get_children():
		_init_posable(child, child.global_position, "");

# Place an element of type 'Posable' on the map at a given position
# Add the element to the _map_objects array
# Save the position (local to grid map) -> the coordinates of a tile in the grid map
func _place_item_at(item_data: Dictionary, _global_position: Vector3, _owner: String = "") -> void:
	if not has_item_at(_global_position):
		var scene: StaticBody3D = load(item_data.scene_path).instantiate();
		_map_items.add_child(scene);
		scene.set_global_position(_global_position);
		_init_posable(scene, _global_position, _owner);
		GridMapEvents.item_placed.emit();
		return;
	# Send event to tell it's not possible to put an item at this given position

func _init_posable(scene: PhysicsBody3D, _global_position: Vector3, _owner: String) -> void:
	var pos = global_to_local(_global_position);
	_map_objects[pos] = scene;
	scene._init_posable(_owner);

func get_map_item(id: String) -> MapItem:
	for key in _map_objects:
		var map_object = _map_objects[key];
		if map_object.id == id:
			return map_object;
	return null;

func has_item_at(position: Vector3) -> bool:
	return _map_objects.has(global_to_local(position));

# Convert a global position (from map point of view) to the grid map position (index of the tile)
func global_to_local(global_position: Vector3) -> Vector3i:
	return (global_position / cell_size).floor();
