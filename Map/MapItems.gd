# This class intends to deal with map items instances
# It can create / delete objects on the map
extends Node3D

func _ready():
	GridMapEvents.place_item_at.connect(_place_item_at);
	
func _place_item_at(item_data: Dictionary, _global_position: Vector3) -> void:
	var scene: StaticBody3D = load(item_data.scene_path).instantiate();
	add_child(scene);
	scene.set_global_position(_global_position);
