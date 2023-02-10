extends StaticBody3D;

@onready var _this_proximity_collider := $ProximityArea/CollisionShape3D;
@onready var _this_collider := $Collider;

# Called when the node enters the scene tree for the first time.
func _ready():
	_set_all_colliders_state(true);
	
func _set_all_colliders_state(state: bool) -> void:
	_this_proximity_collider.set_disabled(state);
	_this_collider.set_disabled(state);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
