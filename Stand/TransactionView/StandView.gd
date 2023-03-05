extends InventoryView
class_name StandTransactionView

@onready var item_value_label = $VBoxContainer/TextureRect/Value;

func _ready():
	pass

func open(_container_id: String) -> void:
	container_id = _container_id;
	_load_container_config();
	var items = MarketController.get_items(container_id);
	_update_items(items);
	visible = true;

func _update_items(items: Dictionary):
	super._update_items(items);
	#item_value_label.text = 

func _input(event):
	pass

func _handle_mouse_click(event: InputEventMouseButton) -> void:
	pass

func close() -> void:
	visible = false;
