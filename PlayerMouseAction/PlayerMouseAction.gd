extends Control

@onready var _label_name = $LabelName;
@onready var _label_amount = $LabelAmount;
@onready var _texture_icon = $TextureIcon;

var _selected_item: Dictionary;
var _selected_item_node: StaticBody3D;

func _ready():
	visible = false;
	InventoryEvents.item_in_container_selected.connect(_set_item);
	InventoryEvents.visibility_current_item.connect(_set_visibility);

func _set_item(item_data: Dictionary):
	_reset_item();
	if !item_data.is_empty():
		_set_visibility(true);
		_selected_item = item_data;
		if _selected_item.type == "Material":
			_set_material_item();
		elif _selected_item.type == "Posable":
			_set_posable_item();

# Set base properties as all items have at least
# id, name, amount and icon
func _set_base_properties() -> void:
	_label_name.text = _selected_item.name;
	_label_amount.text = str(_selected_item.amount);
	_texture_icon.texture = load(_selected_item.icon_path);

func _set_posable_item() -> void:
	InventoryEvents.mouse_outside.connect(_mouse_outside);
	CameraEvents.on_ray_intersect_plane.connect(_put_item_on_map);
	_set_base_properties();

func _set_material_item():
	_set_base_properties();

func _set_visibility(value:bool):
	visible = value;
	
func _reset_item() -> void:
	_set_visibility(false);
	_selected_item = {};
	_label_name.text = '';
	_label_amount.text = '';
	_texture_icon.texture = null;
	if not InventoryEvents.mouse_outside.get_connections().is_empty():
		InventoryEvents.mouse_outside.disconnect(_mouse_outside);
	if not CameraEvents.on_ray_intersect_plane.get_connections().is_empty():
		CameraEvents.on_ray_intersect_plane.disconnect(_put_item_on_map);

func _mouse_outside(status:bool) -> void:
	if _selected_item.type != "Posable":
		return;
	if status:
		if _selected_item_node == null:
			var _scene: PackedScene = load(_selected_item.scene_path);
			_selected_item_node = _scene.instantiate();
			add_child(_selected_item_node);
	elif _selected_item_node != null:
		_selected_item_node.queue_free();

func _put_item_on_map(position: Vector3) -> void:
	if _selected_item_node != null:
		_selected_item_node.set_position(position);

func _input(event):
	if event is InputEventMouseMotion:
		global_position = get_global_mouse_position();
