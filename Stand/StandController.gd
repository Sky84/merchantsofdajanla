extends Posable

@onready var _container: PosableContainer = $Container

func _init_posable(_owner: String):
	super._init_posable(_owner);
	_container.register_container(id, _owner);

func interact(_interract_owner_id: String) -> void:
	print("_container_owner: "+_container._container_owner);
	print("_interract_owner_id: "+_interract_owner_id);
	if _is_interact_from_owner(_interract_owner_id):
		HudEvents.open_stand.emit(_container.container_id);
	else:
		print('buy from _interract_owner_id:'+ _interract_owner_id);
