extends Node3D

@onready var animation_player := $AnimationPlayer;
@onready var action_tooltip := $Label3D;

func _ready():
	animation_player.play("floating_label");
	action_tooltip.set_text(InputMap.action_get_events("use")[0].as_text());
