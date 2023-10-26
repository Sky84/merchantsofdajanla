extends CanvasLayer
@export var root_scene: Node;
@onready var animation_player = $Panel/AnimationPlayer;
var game_scene = preload("res://Game.tscn");

func _on_button_start_pressed():
	animation_player.play("menu_change");
	await animation_player.animation_finished;
	var game_instance = game_scene.instantiate();
	root_scene.add_child(game_instance);
	animation_player.play("fade_out");
	await animation_player.animation_finished;
	NavigationEvents.on_game_scene_ready.emit();
