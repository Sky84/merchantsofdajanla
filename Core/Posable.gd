extends MapItem
class_name Posable

@onready var _collider := $Collider;

func _ready():
	_disable_collider(true);
	super._ready();

func _init_posable():
	_disable_collider(false);
	_update_id();

func _disable_collider(state: bool) -> void:
	_collider.set_disabled(state);
