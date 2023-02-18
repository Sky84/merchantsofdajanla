extends Posable

@onready var _collider := $Collider;

func _ready():
	super._ready();
	_disable_collider(true);
	
func _disable_collider(state: bool) -> void:
	_collider.set_disabled(state);

func _init_posable():
	_disable_collider(false);
