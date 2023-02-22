extends InventoryView
class_name StandTransactionView

func _ready():
	pass

func open(_container_id: String) -> void:
	container_id = _container_id;
	_load_container_config();
	var container_data = ContainersController.get_container_data(container_id);
	_update_items(container_data)
	visible = true;

func _input(event):
	pass

func _handle_mouse_click(event: InputEventMouseButton) -> void:
	pass

func close() -> void:
	visible = false;
