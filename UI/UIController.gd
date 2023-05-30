extends CanvasLayer
class_name UIController

@export var mouse_targets_node_to_exclude: Array[NodePath];

@onready var confirm_dialog: Panel = $ConfirmDialog;
@onready var stand_setup: StandSetupView = $StandSetup;
@onready var stand_transaction: StandTransactionView = $StandTransaction;
@onready var modal_container = $ModalContainer

var tooltip = preload("res://UI/Tooltip/tooltip.tscn").instantiate();
var _nearest_interactive: MapItem = null;
var _current_mouse_target: Control;

# Called when the node enters the scene tree for the first time.
func _ready():
	InventoryEvents.dialog_confirm_delete_item.connect(_show_confirm_dialog);
	HudEvents.open_stand_setup.connect(_show_stand_setup_dialog);
	HudEvents.open_stand_transaction.connect(_show_stand_transaction_dialog);
	PlayerEvents.on_nearest_interactive_changed.connect(_show_tooltip_on_interactive);
	for child in get_children():
		if not mouse_targets_node_to_exclude.has(child.get_path()):
			child.mouse_entered.connect(_om_mouse_current_target.bind(child, true));
			child.mouse_exited.connect(_om_mouse_current_target.bind(child, false));
	HudEvents.open_modal.connect(_on_open_modal);
	modal_container.hide();

func _on_open_modal(path_node_to_instance: String, params: Dictionary):
	var instance = load(path_node_to_instance).instantiate();
	for param in params:
		instance[param] = params[param];
	modal_container.add_child(instance);
	modal_container.show();
	var result = await instance.close_modal;
	modal_container.hide();
	modal_container.remove_child(instance);
	HudEvents.closed_modal.emit(result);

func _show_stand_setup_dialog(container_id: String, screen_position: Vector2) -> void:
	stand_setup.open(container_id, screen_position);

func _show_stand_transaction_dialog(container_id: String, _interract_owner_id: String, screen_position: Vector2) -> void:
	stand_transaction.open(container_id, _interract_owner_id, screen_position);

func _show_confirm_dialog(item):
	var message = tr("DIALOG.CONFIRM_DELETE")+" "+str(item.amount)+" "+tr(item.name)+"(s) ?";
	confirm_dialog.open(message, _on_delete_item.bind(item));

func _on_delete_item(_item):
	InventoryEvents.reset_current_item.emit();

func _om_mouse_current_target(target: Control, is_mouse_hover: bool) -> void:
	var mouse_position = target.get_local_mouse_position();
	var stay_in_child = Rect2(Vector2(), target.size).has_point(mouse_position);
	if not is_mouse_hover and stay_in_child:
		return;
	var target_to_emit = target if is_mouse_hover else null;
	_current_mouse_target = target_to_emit;

func get_current_mouse_target() -> Control:
	return _current_mouse_target;

func _show_tooltip_on_interactive(posable: MapItem) -> void:
	if _nearest_interactive:
		_nearest_interactive.get_interactive_label_container().remove_child(tooltip);
		_nearest_interactive = null;
		stand_transaction.close();
		stand_setup.close();
	if posable:
		_nearest_interactive = posable;
		_nearest_interactive.get_interactive_label_container().add_child(tooltip);
