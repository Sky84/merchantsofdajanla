extends Camera3D

@export var player: CharacterBody3D;
@export var camera_speed: float;
var _offset: Vector3;

var _camera_factor_speed: float = 10.0;

# Called when the node enters the scene tree for the first time.
func _ready():
	_offset = player.position - position;


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	position = position.lerp(player.position - _offset, camera_speed / _camera_factor_speed);
