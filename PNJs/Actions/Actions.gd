extends Node

# Action Ids
const EAT: String = 'Eat';
const BUY: String = 'Buy';
const WAIT: String = 'Wait';

var _triggers := {};
var _actions := {};

var _triggers_json_path = 'AI/Triggers.json';
var _actions_path = 'res://PNJs/Actions/';
var _actions_path_suffix = 'Action.gd';

@onready var navigation_region_3d: NavigationRegion3D = get_node('/root/Root/NavigationRegion3D');

# Called when the node enters the scene tree for the first time.
func _ready():
	_triggers = JsonResourceLoader.load_json(_triggers_json_path);
	for id in _triggers:
		var action: Action = create_action(_triggers[id].action);
		_actions[action.id] = action;
		if action.fallback != null:
			_actions[action.fallback.id] = action.fallback;

func create_action(action: Dictionary) -> Action:
	var instance_action_class: GDScript = load(_actions_path+action.id+_actions_path_suffix) as GDScript;
	var nav_mesh_navigation = navigation_region_3d.navigation_mesh; 
	if "fallback" in action:
		var instance_action_fallback_class = load(_actions_path+action.fallback.id+_actions_path_suffix);
		var fallback_action = instance_action_fallback_class.new(action.fallback.id, action.fallback.target, nav_mesh_navigation);
		return instance_action_class.new(action.id, action.target, nav_mesh_navigation, fallback_action);
	else:
		return instance_action_class.new(action.id, action.target, nav_mesh_navigation);

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


func get_action_by_id(action_id: String) -> Action:
	return _actions.get(action_id);
