extends Posable;

@onready var _collider := $Collider;
@onready var _action_placeholder := $ActionPlaceholder;

func _ready():
	_disable_collider(true);
	
func _disable_collider(state: bool) -> void:
	_collider.set_disabled(state);

func _init_posable():
	_disable_collider(false);

func get_action_placeholder() -> Node3D:
	return _action_placeholder;
