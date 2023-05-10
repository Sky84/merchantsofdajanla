extends Alive

var actions_queue = [];

func _ready():
	_process_actions_queue();

func _process_actions_queue():
	var current_action_id = actions_queue.front();
	if current_action_id:
		_process_action(current_action_id);
	else:
		var action_id = _get_action_id_by_triggers();
		if !action_id.is_empty():
			actions_queue.append(action_id);
	_process_actions_queue();

func _process_action(action_id: String) -> void:
	var action = _get_action_by_id(action_id);
	match action.id:
		'Eat':
			var items_target = GameItems.get_items_by_subtype(action.target);
			# TODO : Faire manger une des targets disponible au PNJ sinon fallback()

func _get_action_by_id(action_id: String) -> Dictionary:
	return {'id':'Eat', 'target': 'Food'};

func _get_action_id_by_triggers() -> String:
	var triggers = [];
	for trigger in triggers:
		var condition_agreed = _check_conditions(trigger.conditions);
		if condition_agreed:
			return trigger.action.id;
	return '';

func _check_conditions(conditions: Array) -> bool:
	for condition in conditions:
		if condition.type == "Hunger":
			if condition.value > _alive_status.hunger.value:
				return false;
			# Ajouter un if si conditions complémentaire Ex. hunger and at home

	return true; # Si toutes les conditions sont satisfaites

