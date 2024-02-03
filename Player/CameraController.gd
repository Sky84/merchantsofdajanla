extends Camera3D;

@export var player: CharacterBody3D;
@export var camera_speed: float;
@export var terrain_collision_mask: int;
@export var _plane_map_node: GameGridMapController;
var _offset: Vector3;
var _camera_factor_speed: float = 10.0;

var _ray_origin = Vector3();
var _ray_end = Vector3();

# Called when the node enters the scene tree for the first time.
func _ready():
	_offset = player.position - position;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	position = position.lerp(player.position - _offset, camera_speed / _camera_factor_speed);


func _physics_process(_delta):
	var _space_state = get_world_3d().direct_space_state;
	var mouse_pos = get_viewport().get_mouse_position();
	_ray_origin = project_ray_origin(mouse_pos);
	_ray_end = _ray_origin + project_ray_normal(mouse_pos) * 2000;
	var intersect_query = PhysicsRayQueryParameters3D.create(_ray_origin, _ray_end, terrain_collision_mask);
	var intersection = _space_state.intersect_ray(intersect_query);
	if not intersection.is_empty():
		var local_pos = (intersection.position/ _plane_map_node.tile_size).floor()
		var _pos = _plane_map_node.local_to_global(local_pos);
		CameraEvents.on_ray_intersect_plane.emit(_pos, intersection.collider);
