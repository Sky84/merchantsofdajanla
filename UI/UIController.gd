extends CanvasLayer
class_name UIController

@export var mouse_targets_node_to_exclude: Array[NodePath];

@onready var confirm_dialog: Panel = $ConfirmDialog;

var tooltip = preload("res://UI/Tooltip/tooltip.tscn").instantiate();
var _nearest_interactive: MapItem = null;
var _current_mouse_target: Control;

# Called when the node enters the scene tree for the first time.
func _ready():
	InventoryEvents.dialog_confirm_delete_item.connect(_show_dialog);
	PlayerEvents._on_nearest_interactive_changed.connect(_show_tooltip_on_interactive);
	for child in get_children():
		if not mouse_targets_node_to_exclude.has(child.get_path()):
			child.mouse_entered.connect(_om_mouse_current_target.bind(child));
			child.mouse_exited.connect(_om_mouse_current_target.bind(null));

func _show_dialog(item):
	var message = tr("DIALOG.CONFIRM_DELETE")+" "+str(item.amount)+" "+tr(item.name)+"(s) ?";
	confirm_dialog.open(message, _on_delete_item.bind(item));

func _on_delete_item(_item):
	InventoryEvents.reset_current_item.emit();

func _om_mouse_current_target(target: Control) -> void:
	HudEvents.on_mouse_current_target.emit(target);

func _show_tooltip_on_interactive(posable: MapItem) -> void:
	if _nearest_interactive:
		_nearest_interactive.get_interactive_label_container().remove_child(tooltip);
		_nearest_interactive = null;
	if posable:
		_nearest_interactive = posable;
		_nearest_interactive.get_interactive_label_container().add_child(tooltip);
