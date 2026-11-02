extends Posable

@onready var _container: PosableContainer = $Container;
@onready var _camera = get_node("/root/Root/Game/Camera3D");

func _init_posable(__owner: String) -> void:
	await super._init_posable(__owner);
	_container.register_container(id, __owner);

func interact(_interract_owner_id: String) -> void:
	var screen_position = _camera.unproject_position(global_position) - Vector2(64, 80);
	HudEvents.open_stand_setup.emit(_container.container_id, screen_position);
