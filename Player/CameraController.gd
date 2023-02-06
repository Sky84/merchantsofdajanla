extends Camera3D;

@export var player: CharacterBody3D;
@export var camera_speed: float;
@onready var _ray := $RayCast3D;
@onready var _grid_map := $"../GridMap";
var _offset: Vector3;
var _camera_factor_speed: float = 10.0;

var _ray_origin = Vector3();
var _ray_end = Vector3();

# Called when the node enters the scene tree for the first time.
func _ready():
	_offset = player.position - position;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position = position.lerp(player.position - _offset, camera_speed / _camera_factor_speed);
	if (_ray.is_colliding()):
		print(_ray.get_collision_point());


func _input(event):
	if event is InputEventMouseMotion:
		var _space_state = get_world_3d().direct_space_state;
		var mouse_pos = event.position;
		_ray_origin = project_ray_origin(mouse_pos);
		_ray_end = _ray_origin + project_ray_normal(mouse_pos) * 2000;
		var intersect_query = PhysicsRayQueryParameters3D.create(_ray_origin, _ray_end);
		var intersection = _space_state.intersect_ray(intersect_query);
		if not intersection.is_empty():
			print(intersection.position);
			CameraEvents.emit_signal("on_ray_intersect_plane", intersection.position);

#		_ray_origin = project_ray_origin(mouse_pos);
#		var _direction = project_ray_normal(mouse_pos);
#		if _direction.y == 0:
#			return;
#		var _dist = -_ray_origin.y / _direction.y;
#		var _position = _ray_origin + _direction * _dist;
#		var _pos = _grid_map.map_to_local(_position / _grid_map.cell_size);
#		if _pos.x < 0:
#			_pos.x += 1;
#		CameraEvents.emit_signal("on_ray_intersect_plane", _pos);
