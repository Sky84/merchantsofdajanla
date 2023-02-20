extends Posable

@onready var _container: PosableContainer = $Container

func _init_posable():
	super._init_posable();
	_container.register_container(id);

func interact() -> void:
	HudEvents.open_stand.emit(_container.container_id);
