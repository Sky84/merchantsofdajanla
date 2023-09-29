extends MapItem
class_name Posable

@onready var _collider := $Collider;

func _ready():
	_disable_collider(true);

func _init_posable(_owner: String):
	if !is_node_ready():
		await ready;
	self._owner = _owner;
	_disable_collider(false);
	_update_id();

func _disable_collider(state: bool) -> void:
	_collider.set_disabled(state);

func _is_interact_from_owner(interact_owner: String) -> bool:
	return interact_owner == self._owner;
