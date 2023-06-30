extends Node

class DialogNode:
	var _id: String;
	var _value: String;
	var _type: String;
	var _next_nodes: Array;
	func _init(id: String, value: String, type: String, next_nodes: Array = []):
		_id = id;
		_value = value;
		_type = type;
		_next_nodes = next_nodes;

class DialogState:
	var _questions: Dictionary = {};
	var _answers: Dictionary = {};
	var _current: DialogNode = null;
	
	var current: DialogNode:
		get:
			return _current;
	
	func _init(questions: Dictionary, answers: Dictionary):
		_questions = questions;
		_answers = answers;
		_load_current("1");
	
	func _load_current(id: String) -> void:
		var current_question = _questions[id];
		var current_answers = [];
		for answer_id in current_question.next_nodes:
			var current_answer = _answers[answer_id];
			current_answers.push_back(DialogNode.new(answer_id, current_answer.value, "answer"));
		_current = DialogNode.new(id, current_question.value, "question", current_answers);
	
	func get_next_node(choice_id: String) -> DialogNode:
		_load_current(choice_id);
		return _current;

var dialogs_config: Dictionary;
var state: DialogState;

func _init():
	dialogs_config = JsonResourceLoader.load_json("Dialogs/Dialogs.json");

func load_dialog(dialog_type: String) -> DialogState:
	return _init_state(dialogs_config[dialog_type]);

func _init_state(dialog_data_path: String) -> DialogState:
	var questions = JsonResourceLoader.load_json(dialog_data_path + 'Questions.json');
	var answers = JsonResourceLoader.load_json(dialog_data_path + 'Answers.json');
	state = DialogState.new(questions, answers);
	return state;
