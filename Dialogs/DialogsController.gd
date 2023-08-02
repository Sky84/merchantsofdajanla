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
