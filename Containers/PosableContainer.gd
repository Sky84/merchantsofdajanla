extends ItemsContainer
class_name PosableContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func register_container(_container_id: String):
	container_id = _container_id;
	ContainersController.register_container(container_id, rows, columns, _items);
	ContainersController.update(container_id, _items);
