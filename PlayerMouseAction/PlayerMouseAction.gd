extends Control

@onready var _label_name = $LabelName;
@onready var _label_amount = $LabelAmount;
@onready var _texture_icon = $TextureIcon;
@onready var _camera = $"../../Camera3D";

var _selected_item_id: String;
var _selected_item_scene_path: String;
var _selected_item_node: StaticBody3D;

func _ready():
	visible = false;
	_camera.ray_position_on_plane.connect();
	InventoryEvents.item_in_container_selected.connect(_set_item);
	InventoryEvents.visibility_current_item.connect(_set_visibility);
	InventoryEvents.mouse_in_view.connect(_mouse_in_view)

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

func _set_visibility(value:bool):
	visible = value;

func _mouse_in_view(status:bool) -> void:
	if status && !_selected_item_scene_path.is_empty():
		#instancier le model si necessaire (cad -> si item_data.scene_path) existe
		var _scene: PackedScene = load(_selected_item_scene_path);
		_selected_item_node = _scene.instantiate();
		add_child(_selected_item_node);
	elif _selected_item_node != null:
		_selected_item_node.queue_free();

func _input(event):
	if event is InputEventMouseMotion:
		global_position = get_global_mouse_position();
