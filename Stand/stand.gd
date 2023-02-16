extends StaticBody3D;

@onready var _proximity_collider := $ProximityArea/CollisionShape3D;
@onready var _collider := $Collider;

# Called when the node enters the scene tree for the first time.
func _ready():
	_disable_all_colliders(true);
	
func _disable_all_colliders(state: bool) -> void:
	_proximity_collider.set_disabled(state);
	_collider.set_disabled(state);

func _init_posable():
	_disable_all_colliders(false);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass;
