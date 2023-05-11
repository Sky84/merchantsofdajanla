extends Node

# Action Ids
const EAT: String = 'Eat';

var _triggers := {};
var _actions := {};

var _triggers_json_path = 'AI/Triggers.json';

# Called when the node enters the scene tree for the first time.
func _ready():
	_triggers = JsonResourceLoader.load_json(_triggers_json_path);
	for id in _triggers:
		_actions[_triggers[id].action.id] = _triggers[id].action;
		_actions[_triggers[id].action.fallback.id] = _triggers[id].action.fallback;

# TODO: Ne passer que l'id du Alive et le get dans la fonction pour ne pas avoir acces qu'a _alive_status
func get_action_id_by_triggers(_alive_status: Dictionary) -> String:
	for id in _triggers:
		var trigger = _triggers[id];
		var condition_agreed = _check_conditions(trigger.conditions, _alive_status);
		if condition_agreed:
			return trigger.action.id;
	return '';

func _check_conditions(conditions: Array, _alive_status: Dictionary) -> bool:
	for condition in conditions:
		if condition.type == "Hunger":
			if _alive_status.hunger.value > condition.value:
				return false;
			# Ajouter un if si conditions complémentaire Ex. hunger and at home

	return true; # Si toutes les conditions sont satisfaites


func get_action_by_id(action_id: String) -> Dictionary:
	return _actions.get(action_id);

func try_eat(action: Dictionary, container_owner_id: String, consume_callback: Callable,
 fallback_callback: Callable) -> void:
	var items_target: Array[Dictionary] = GameItems.get_items_by_subtype(action.target);
	var container_ids: Array[String] = ContainersController.get_container_ids_by_owner_id(container_owner_id);
	var item_to_eat = items_target.map(
		func(item: Dictionary):
			return ContainersController.find_item_in_containers(container_ids, item.id)
	);
	if !item_to_eat.is_empty():
		consume_callback.call(item_to_eat[0].item);
	else:
		fallback_callback.call(action.fallback);
