extends Camera3D

@export var player: CharacterBody3D;
@export var offset: Vector3;
@export var camera_speed: float;

var _camera_factor_speed: float = 10.0;

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position = position.lerp(player.position - offset, camera_speed / _camera_factor_speed);
