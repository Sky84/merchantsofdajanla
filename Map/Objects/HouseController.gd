extends StaticBody3D

@export var can_enter: bool = false;
@export var interior_scene: PackedScene;

@onready var house_id: String = 'house_'+str(global_position.x)+'_'+str(global_position.y);
@onready var game_map_controller: GameMapController = get_node('/root/Root/Game/GameMapController'); 

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_enter_area_3d_body_entered(body: Node3D):
	if body is Alive:
		var interior_instance: GridMap;
		if house_id in game_map_controller.spawned_interior_houses:
			interior_instance = get_node(game_map_controller.spawned_interior_houses[house_id].node_path);
		else:
			interior_instance = game_map_controller.add_interior_house(house_id, interior_scene);
		body.global_position = interior_instance.get_node("Spawn").global_position;
		interior_instance.rotation_degrees = rotation_degrees;
		interior_instance.get_node('ExitArea3D').body_entered.connect(_on_exit_area_3d_body_entered);

func _on_exit_area_3d_body_entered(body: Node3D):
	var interior_instance = get_node(game_map_controller.spawned_interior_houses[house_id].node_path);
	interior_instance.get_node('ExitArea3D').body_entered.disconnect(_on_exit_area_3d_body_entered);
	if body is Alive:
		body.global_position = get_node("ExitSpawn").global_position;
