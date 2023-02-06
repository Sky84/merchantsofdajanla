extends Control

@onready var _label_name = $LabelName;
@onready var _label_amount = $LabelAmount;
@onready var _texture_icon = $TextureIcon;

var _selected_item_id: String;
var _selected_item_scene_path: String;
var _selected_item_node: StaticBody3D;

func _ready():
	visible = false;
	InventoryEvents.item_in_container_selected.connect(_set_item);
	InventoryEvents.visibility_current_item.connect(_set_visibility);
	InventoryEvents.mouse_in_view.connect(_mouse_in_view);

func _set_item(item_data: Dictionary):
	if !item_data.is_empty():
		visible = true;
		_selected_item_id = item_data.id;
		_label_name.text = item_data.name;
		_label_amount.text = str(item_data.amount);
		_texture_icon.texture = load(item_data.icon_path);
		_selected_item_scene_path = item_data.scene_path;
	else:
		visible = false;
		_selected_item_scene_path = "";

func _set_visibility(value:bool):
	visible = value;

func _mouse_in_view(status:bool) -> void:
	if status && !_selected_item_scene_path.is_empty():
		CameraEvents.on_ray_intersect_plane.connect(_put_item_on_map);
		#instancier le model si necessaire (cad -> si item_data.scene_path) existe
		var _scene: PackedScene = load(_selected_item_scene_path);
		_selected_item_node = _scene.instantiate();		
		add_child(_selected_item_node);
	elif _selected_item_node != null:
		CameraEvents.disconnect("on_ray_intersect_plane", _put_item_on_map);
		_selected_item_node.queue_free();
		
func _put_item_on_map(position: Vector3) -> void:
	print('position is', position);
	if _selected_item_node != null:
		_selected_item_node.set_position(position);

func _input(event):
	if event is InputEventMouseMotion:
		global_position = get_global_mouse_position();
