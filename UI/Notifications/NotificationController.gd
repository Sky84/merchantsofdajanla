extends Control

@onready var _grid_container: GridContainer = $GridContainer

var _notification_scene: PackedScene = preload("res://UI/Notifications/Notification.tscn");

# Called when the node enters the scene tree for the first time.
func _ready():
	NotificationEvents.notify.connect(_on_notify);

func _on_notify(type: String, message: String) -> void:
	var notification_instance = _notification_scene.instantiate();
	_grid_container.add_child(notification_instance);
	notification_instance.init_notification(type, message);
	notification_instance.on_hide_finished.connect(
		func ():
			notification_instance.queue_free();
			_grid_container.remove_child(notification_instance);
	);
