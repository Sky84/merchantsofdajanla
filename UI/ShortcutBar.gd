extends InventoryView

var index_position_selector: int = 0;

# Called when the node enters the scene tree for the first time.
func _ready():
	if container_id == null:
		printerr("container_id is not set");
	InventoryEvents.reset_current_item.connect(_on_reset_current_item);
	InventoryEvents.container_data_changed.connect(_update_shortcut_bar);
	ContainersController.on_registered_container.connect(on_registered_container);

func on_registered_container(registered_container_id: String) -> void:
	super(registered_container_id);
	_update_shortcut_bar(container_id);

func _update_shortcut_bar(_container_id: String) -> void:
	if container_id == _container_id:
		var slots = ContainersController.get_container_data(container_id);
		_update_items(slots);

func _update_selector_position():
	var local_mouse_position = Vector2(index_position_selector, 0);
	local_mouse_position.x = clamp(local_mouse_position.x, 0, _items_container.columns-1);
	var hover_texture_position = (local_mouse_position * item_with_gap) - offset_hover_selector;
	hover_texture.position = _items_container.position + hover_texture_position;

func _input(event):
	if _container_owner.is_empty():
		return;
	if event is InputEventMouse:
		var value_to_add: int = event.get_action_strength("mouse_scroll_up") - event.get_action_strength("mouse_scroll_down");
		index_position_selector = fposmod(index_position_selector + value_to_add, _items_container.columns);
		if event is InputEventMouseButton and ContainersController.current_item.value \
			and ui_controller.get_current_mouse_target() == null:
			check_mouse_outside();
			_handle_mouse_click(event);
	_update_selector_position();
	_update_item_in_hand();
	
func _update_item_in_hand():
	var slots = ContainersController.get_container_data(container_id);
	var item_selected = slots[index_position_selector][0];
	PlayerEvents.on_item_in_hand_changed.emit(item_selected);
