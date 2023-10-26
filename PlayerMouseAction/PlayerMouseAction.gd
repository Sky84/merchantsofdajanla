extends Control

@onready var _label_name = $LabelName;
@onready var _label_amount = $LabelAmount;
@onready var _texture_icon = $TextureIcon;

var _selected_item: Dictionary;
var _selected_item_node: StaticBody3D;

var _posable_collider: Area3D;

func _ready():
	visible = false;
	InventoryEvents.item_in_container_selected.connect(_set_item);
	InventoryEvents.visibility_current_item.connect(_set_visibility);
	HudEvents.update_player_mouse_action.connect(_set_base_properties);

func _set_item(item_data: Dictionary):
	if !item_data.is_empty():
		_set_visibility(true);
		_selected_item = item_data;
		match _selected_item.type:
			"Material", "Consomable":
				_set_material_item();
			"Posable":
				_set_posable_item();
	else:
		_reset_item();

# Set base properties as all items have at least
# id, name, amount and icon
func _set_base_properties() -> void:
	_label_name.text = _selected_item.name;
	_label_amount.text = str(_selected_item.amount);
	_texture_icon.texture = load(_selected_item.icon_path);

func _set_posable_item() -> void:
	if not InventoryEvents.mouse_outside.is_connected(_mouse_outside):
		InventoryEvents.mouse_outside.connect(_mouse_outside);
	if not CameraEvents.on_ray_intersect_plane.is_connected(_preview_item_on_map):
		CameraEvents.on_ray_intersect_plane.connect(_preview_item_on_map);
	if not InventoryEvents.place_item_on_map.is_connected(_place_item_on_map):
		InventoryEvents.place_item_on_map.connect(_place_item_on_map);
	_set_base_properties();

func _set_material_item():
	_set_base_properties();

func _set_visibility(value:bool):
	visible = value;
	
func _reset_item() -> void:
	_set_visibility(false);
	_label_name.text = '';
	_label_amount.text = '';
	_texture_icon.texture = null;
	if InventoryEvents.mouse_outside.is_connected(_mouse_outside):
		InventoryEvents.mouse_outside.disconnect(_mouse_outside);
	if CameraEvents.on_ray_intersect_plane.is_connected(_preview_item_on_map):
		CameraEvents.on_ray_intersect_plane.disconnect(_preview_item_on_map);
	if InventoryEvents.place_item_on_map.is_connected(_place_item_on_map):
		InventoryEvents.place_item_on_map.disconnect(_place_item_on_map);
	if _selected_item_node != null:
		_destroy_posable_preview();

func _create_posable_preview() -> void:
	var _scene: PackedScene = load(_selected_item.scene_path);
	_selected_item_node = _scene.instantiate();
	add_child(_selected_item_node);
	
func _destroy_posable_preview() -> void:
	var mesh = NodeUtils.get_mesh_in_child(_selected_item_node);
	# workaround to prevent godot error not already fixed about duplicated material 
	mesh.set_surface_override_material(0, null);
	_selected_item_node.queue_free();

func _mouse_outside(status:bool) -> void:
	if _selected_item.type != "Posable":
		return;
	if status:
		if _selected_item_node == null:
			_create_posable_preview();
	elif _selected_item_node != null:
		_destroy_posable_preview();

func _preview_item_on_map(position: Vector3, _plane_map: GameGridMapController) -> void:
	if _selected_item_node != null:
		_selected_item_node.set_position(position);
		var mesh_instance: MeshInstance3D = NodeUtils.get_mesh_in_child(_selected_item_node);
		var _material: StandardMaterial3D = mesh_instance.mesh.surface_get_material(0).duplicate(true);
		_material.albedo_color = Color(1, 0, 0) if _plane_map.has_item_at(position) else Color(1,1,1);
		mesh_instance.set_surface_override_material(0, _material);

func _input(event):
	if event is InputEventMouseMotion:
		global_position = get_global_mouse_position();

func _place_item_on_map(item: Dictionary, container_owner: String) -> void:
	GridMapEvents.place_item_at.emit(_selected_item, _selected_item_node.global_position, container_owner);

func _create_posable_collider() -> void:
	_posable_collider = Area3D.new();
