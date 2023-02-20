extends InventoryView

var index_position_selector: int = 0;

# Called when the node enters the scene tree for the first time.
func _ready():
	if container_id == null:
		printerr("container_id is not set");
	if rows == 0:
		printerr("rows is not set");
	InventoryEvents.container_data_changed.connect(_on_data_changed);
	InventoryEvents.reset_current_item.connect(_on_reset_current_item);

func _update_selector_position():
	var local_mouse_position = Vector2(index_position_selector, 0);
	local_mouse_position.x = clamp(local_mouse_position.x, 0, _items_container.columns-1);
	var hover_texture_position = (local_mouse_position * item_with_gap) - offset_hover_selector;
	hover_texture.position = _items_container.position + hover_texture_position;

func _input(event):
	if event is InputEventMouse:
		var value_to_add: int = event.get_action_strength("mouse_scroll_up") - event.get_action_strength("mouse_scroll_down");
		index_position_selector = fposmod(index_position_selector + value_to_add, _items_container.columns);
	if event is InputEventMouseButton and _current_item:
		var click_outside = !get_rect().has_point(event.position); 
		if (click_outside and !event.is_pressed()):
			InventoryEvents.dialog_confirm_delete_item.emit(_current_item);
	_update_selector_position();
