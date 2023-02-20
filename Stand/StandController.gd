extends Posable

@onready var _container: ItemsContainer = $Container

func _init_posable():
	super._init_posable();
	_container.container_id = id;

func interact() -> void:
	print(_container.container_id)
