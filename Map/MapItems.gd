# This class intends to deal with map items instances
# It can create / delete objects on the map
extends GridMap

@onready var _map_items = $MapItems;
var _map_objects := {};

func _ready():
	GridMapEvents.place_item_at.connect(_place_item_at);

# Place an element of type 'Posable' on the map at a given position
# Add the element to the _map_objects array
# Save the position (local to grid map) -> the coordinates of a tile in the grid map
func _place_item_at(item_data: Dictionary, _global_position: Vector3) -> void:
	if not has_item_at(_global_position):
		var scene: StaticBody3D = load(item_data.scene_path).instantiate();
		_map_items.add_child(scene);
		scene.set_global_position(_global_position);
		var pos = _global_to_local(_global_position);
		_map_objects[pos] = scene;
		scene._init_posable();
		GridMapEvents.item_placed.emit();
		return;
	# Send event to tell it's not possible to put an item at this given position

func has_item_at(position: Vector3) -> bool:
	return _map_objects.has(_global_to_local(position));

# Convert a global position (from map point of view) to the grid map position (index of the tile)
func _global_to_local(global_position: Vector3) -> Vector3i:
	return (global_position / cell_size).floor();
