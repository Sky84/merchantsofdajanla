extends CanvasLayer
@export var root_scene: Node;
@onready var animation_player = $Panel/AnimationPlayer;
var game_scene = preload("res://Game.tscn");

func _ready():
	animation_player.current_animation = "menu_change";
	animation_player.stop();

func _on_button_start_pressed():
	animation_player.play("menu_change");
	await animation_player.animation_finished;
	var game_instance = game_scene.instantiate();
	root_scene.add_child(game_instance);
	animation_player.play("fade_out");
	await animation_player.animation_finished;
	NavigationEvents.on_game_scene_ready.emit();

func _on_button_reset_save_pressed():
	DirAccess.remove_absolute("user://savegame.json");
	$Panel/VBoxContainer/ButtonResetSave.text = "SAVE RESET";
	await get_tree().create_timer(1.5).timeout;
	$Panel/VBoxContainer/ButtonResetSave.text = "MAIN_MENU.RESET_SAVE";
