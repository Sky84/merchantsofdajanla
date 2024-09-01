extends StaticBody3D
class_name ExteriorHouseController

@export var can_enter: bool = false;
@export var interior_scene: PackedScene;

@onready var house_id: String = 'house_'+str(global_position.x)+'_'+str(global_position.y);
@onready var game_map_controller: GameMapController = get_node('/root/Root/Game/GameMapController');
@onready var door_instance = $Door;

func _ready():
	door_instance.door_activated.connect(_on_enter_area_3d_body_entered);

func _on_enter_area_3d_body_entered(owner_id: String):
	var body = AlivesController.get_alive_by_owner_id(owner_id);
	if body is Alive:
		var interior_instance: Node3D;
		if house_id in game_map_controller.spawned_interior_houses:
			interior_instance = get_node(game_map_controller.spawned_interior_houses[house_id].node_path);
		else:
			interior_instance = game_map_controller.add_interior_house(house_id, interior_scene, $ExitSpawn.global_position);
		body.current_interior = interior_instance;
		body.current_exterior_house = self;
		body.global_position = interior_instance.get_node("Spawn").global_position;
