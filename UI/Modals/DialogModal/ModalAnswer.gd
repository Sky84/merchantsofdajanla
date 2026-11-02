extends NinePatchRect
class_name ModalAnswer

@export var _normal_texture: Texture;
@export var _hover_texture: Texture;
@export var _ask_dialog: AskDialog;
var _callback: Callable;
var dialog_node_id := '';
var forced_min_width := 0.0;

const ANSWER_MAX_WIDTH := 260.0;
const ANSWER_MIN_SIZE := Vector2(60, 40);
const ANSWER_PADDING := Vector2(22, 10);

@onready var label = $Label;

var text: String:
	get:
		return label.text;
	set(value):
		if label == null:
			await ready;
		label.text = value;
		_fit_to_text();

func _ready():
	mouse_entered.connect(_on_mouse_entered);
	mouse_exited.connect(_on_mouse_exited);
	call_deferred("_fit_to_text");

func _fit_to_text() -> void:
	var tree = get_tree();
	label.autowrap_mode = TextServer.AUTOWRAP_OFF;
	await tree.process_frame;
	if not is_instance_valid(self):
		return;
	var content_w = min(label.get_combined_minimum_size().x, ANSWER_MAX_WIDTH);
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART;
	label.custom_minimum_size.x = content_w;
	custom_minimum_size.x = max(ANSWER_MIN_SIZE.x, forced_min_width, content_w + ANSWER_PADDING.x);
	size.x = custom_minimum_size.x;
	await tree.process_frame;
	if not is_instance_valid(self):
		return;
	custom_minimum_size.y = max(ANSWER_MIN_SIZE.y, label.get_combined_minimum_size().y + ANSWER_PADDING.y);
	size = custom_minimum_size;

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if _callback:
			_callback.call();
		_ask_dialog.close_parent_modal(dialog_node_id);

func _on_mouse_entered():
	texture = _hover_texture;

func _on_mouse_exited():
	texture = _normal_texture;
