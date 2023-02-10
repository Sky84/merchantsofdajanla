extends CanvasLayer

@onready var confirm_dialog: Panel = $ConfirmDialog

# Called when the node enters the scene tree for the first time.
func _ready():
	InventoryEvents.dialog_confirm_delete_item.connect(_show_dialog);

func _show_dialog(item):
	var message = tr("DIALOG.CONFIRM_DELETE")+" "+str(item.amount)+" "+tr(item.name)+"(s) ?";
	confirm_dialog.open(message, _on_delete_item.bind(item));

func _on_delete_item(_item):
	InventoryEvents.reset_current_item.emit();
