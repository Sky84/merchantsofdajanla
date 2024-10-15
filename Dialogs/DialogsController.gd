extends Node

var dialogs_config: Dictionary;
var state: DialogState;

func _init():
	dialogs_config = JsonResourceLoader.load_json("Dialogs/Dialogs.json");

func load_dialog(dialog_type: String) -> DialogState:
	return _init_state(dialogs_config[dialog_type]);
	
func next(selected_answer_id: String) -> void:
	state.get_next_node(selected_answer_id);

func _init_state(dialog_data_path: String) -> DialogState:
	var questions = JsonResourceLoader.load_json(dialog_data_path + 'Questions.json');
	var answers = JsonResourceLoader.load_json(dialog_data_path + 'Answers.json');
	state = DialogState.new(questions, answers);
	return state;

func get_answers_from_dialog_state(_self_context, dialog_state: DialogState) -> Array:
	var answers := [];
	for answer in dialog_state.next_nodes:
		answers.push_front(_build_answer_config(_self_context, answer));
	return answers;

func _get_answer_params(_self_context, answer: DialogNode) -> Array:
	var params := [];
	for param_key in answer.callback_params:
		params.push_back(_self_context[param_key]);
	return params;

func _build_answer_config(_self_context, answer: DialogNode) -> Dictionary:
	var answer_config := {
		'text': answer.value
	};
	if answer.has_next_nodes:
		answer_config.dialog_node_id = answer.next_nodes[0];
	if answer.has_callback:
		answer_config.callback = _self_context[answer.callback_name].bindv(_get_answer_params(_self_context, answer));
	
	return answer_config;