extends BaseModal
class_name AskDialog

@onready var _indicator_left: TextureRect = $AskContainer/IndicatorLeft;
@onready var _indicator_right: TextureRect = $AskContainer/IndicatorRight;
@onready var _ask_label: Label = $AskContainer/AskLabel;
@onready var _name_label: Label = $AskContainer/NameContainer/NameLabel;
@onready var _answers_container = $AnswersContainer;

var _answer_scene: PackedScene = preload("res://UI/Modals/DialogModal/answer.tscn");

signal close_modal();

var modal_on_left: bool = false;
var ask_translation: String;
var name_translation: String;
var answers: Array;

func _ready():
	_indicator_left.visible = modal_on_left;
	_indicator_right.visible = !modal_on_left;
	_ask_label.text = ask_translation;
	_name_label.text = name_translation;
	for answer in answers:
		var answer_instance: ModalAnswer = _answer_scene.instantiate();
		answer_instance._ask_dialog = self;
		answer_instance._callback = answer.callback if answer.has('callback') else Callable();
		answer_instance.text = answer.text;
		answer_instance.dialog_node_id = answer.dialog_node_id if answer.has('dialog_node_id') else '';
		_answers_container.add_child(answer_instance);

func close_parent_modal(last_node_id: String):
	close_modal.emit();
	HudEvents.close_modal.emit(id, last_node_id);

