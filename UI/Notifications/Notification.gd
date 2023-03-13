extends Control

@export var time_sec_before_destroy: int;

@onready var _label: Label = $Label;
@onready var _animation_player = $AnimationPlayer
@onready var _timer = $Timer

const background_suffix = 'TextureRect';

signal on_hide_finished();

func _ready():
	for type in NotificationEvents.NotificationType.keys():
		var background: TextureRect = get_node(type.to_pascal_case()+background_suffix);
		background.hide();

func init_notification(type: String, message: String) -> void:
	var background: TextureRect = get_node(type.to_pascal_case()+background_suffix);
	background.show();
	_label.text = message;
	_animation_player.play("show");
	_timer.start(time_sec_before_destroy);

func _on_timer_timeout():
	_animation_player.play("hide");

func _on_hide_finished():
	on_hide_finished.emit();
