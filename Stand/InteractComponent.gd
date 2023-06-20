extends Node3D
class_name InteractComponent

const SCENE_NAME := 'InteractComponent';
@onready var interactive_label_container := $InteractiveLabelContainer;

func _ready():
	assert("interact" in get_parent());
