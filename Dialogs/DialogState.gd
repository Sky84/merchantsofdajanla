class_name DialogState

var _questions: Dictionary = {};
var _answers: Dictionary = {};
var _current: DialogNode = null;

var current: DialogNode:
	get:
		return _current;

var next_nodes: Array:
	get:
		return _current.next_nodes;

func _init(questions: Dictionary, answers: Dictionary):
	_questions = questions;
	_answers = answers;
	_load_current("1");

func _load_current(id: String) -> void:
	if not id.length():
		_current = null;
		return;
	var current_question = _questions[id];
	var current_answers = [];
	for answer_id in current_question.next_nodes:
		var current_answer = _answers[answer_id];
		current_answers.push_back(DialogNode.new(answer_id, current_answer.value, current_answer.callback, current_answer.params, current_answer.next_nodes));
	_current = DialogNode.new(id, current_question.value, "", [], current_answers);

func get_next_node(selected_answer_id: String) -> DialogNode:
	_load_current(selected_answer_id);
	return _current;
