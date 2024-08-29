extends Node3D
class_name InteriorBasicHouse


@onready var door_instance := $Door;

var go_to_location: Vector3;

# Called when the node enters the scene tree for the first time.
func _ready():
	door_instance.door_activated.connect(_on_door_activated);

func _on_door_activated(owner_id: String) -> void:
	var alive : Alive = AlivesController.get_alive_by_owner_id(owner_id);
	if alive:
		alive.global_position = go_to_location;
		alive.current_interior = null;
		alive.current_exterior_house = null;
