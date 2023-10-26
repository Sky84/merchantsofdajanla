# This class intends to deal with map items instances
# It can create / delete objects on the map
extends Node3D
class_name GameGridMapController

@export var tile_size = 32;

@onready var _map_items = $MapItems;
@onready var _map_decorations = $MapDecorations;
var _map_objects := {};

func _ready():
	GridMapEvents.place_item_at.connect(_place_item_at);
	_map_items.child_entered_tree.connect(func(child): _init_posable(child, child.global_position, ""));
	_map_decorations.child_entered_tree.connect(func(child): _init_decorations(child,));

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

func _init_decorations(scene: Node3D) -> void:
	var animation_player: AnimationPlayer = scene.get_node_or_null('AnimationPlayer');
	if scene is AnimatedSprite3D:
		scene.play();
	if scene.get_node_or_null('AnimationPlayer'):
		animation_player.play('default');

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

# Convert a global position (from map point of view) to the map position (index of the tile)
func global_to_local(global_position: Vector3) -> Vector3i:
	return (global_position / tile_size).floor();
	
# Convert a local position (from map point of view) to the map position (index of the tile)
func local_to_global(local_position: Vector3) -> Vector3:
	return local_position * tile_size;
