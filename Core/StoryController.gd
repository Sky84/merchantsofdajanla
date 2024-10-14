extends Node
class_name StoryController

@onready var _player = get_node("../Player");
@onready var _game_map = get_node("../GameMapController");

enum StoryState {
	BEFORE_INTRODUCTION,
	AFTER_INTRODUCTION
}

var _stories = {
	StoryState.BEFORE_INTRODUCTION: "res://Data/BeforeIntroductionStory.tscn",
}

func _ready() -> void:
	_set_story_state(StoryState.BEFORE_INTRODUCTION);

func _set_story_state(new_state: StoryState) -> void:
	if new_state not in _stories:
		printerr("Invalid story state: " + str(new_state));
		return;
	if get_child_count() > 0:
		remove_child(get_child(0))
	var story_state = load(_stories[new_state]);
	var story_state_instance = story_state.instantiate();
	add_child(story_state_instance);
	story_state_instance.play_state(_game_map, _player);
