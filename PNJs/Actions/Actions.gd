extends Node

# Action Ids
const EAT: String = 'Eat';
const BUY: String = 'Buy';
const WAIT: String = 'Wait';

var _triggers := {};
var _actions := {};

var _triggers_json_path = 'AI/Triggers.json';
var _actions_json_path = 'AI/Actions.json';
var _actions_path = 'res://PNJs/Actions/';
var _actions_path_suffix = 'Action.gd';

@onready var navigation_region_3d: NavigationRegion3D = get_node('/root/Root/NavigationRegion3D');

var last_game_time: Dictionary = {'hour': 0, 'minute': 0};

# Called when the node enters the scene tree for the first time.
func _ready():
	GameTimeEvents.on_game_time_changed.connect(func(game_time: Dictionary): last_game_time = game_time);
	
	_triggers = JsonResourceLoader.load_json(_triggers_json_path);
	var actions_from_json = JsonResourceLoader.load_json(_actions_json_path);
	for action_json in actions_from_json:
		var action: Action = create_action(action_json);
		_actions[action.id] = action;

func create_action(action: Dictionary) -> Action:
	var instance_action_class: GDScript = load(_actions_path+action.id+_actions_path_suffix) as GDScript;
	var nav_mesh_navigation = navigation_region_3d.navigation_mesh;
	return instance_action_class.new(action.id, action.target, action.params, nav_mesh_navigation);

func get_action_id_by_triggers(owner_id: String) -> String:
	for id in _triggers:
		var trigger = _triggers[id];
		var condition_agreed = _check_conditions(trigger.conditions, owner_id);
		if condition_agreed:
			return trigger.action_id;
	return '';

func _check_conditions(conditions: Array, owner_id: String) -> bool:
	var validated = true;
	for condition in conditions:
		validated = self[condition.validator.name].call(condition.validator, owner_id);
		if !validated:
			break;
	return validated; # Si toutes les conditions sont satisfaites

func _is_game_time_between_value(game_time: Dictionary, value: Dictionary):
	var is_between = false;
	if value.min.hour < value.max.hour:
		if value.min.hour <= game_time.hour and game_time.hour <= value.max.hour:
			is_between = true;
	elif value.min.hour > value.max.hour:
		if game_time.hour >= value.min.hour or game_time.hour <= value.max.hour:
			is_between = true;
	else:
		if value.min.hour == game_time.hour:
			if value.min.minute <= game_time.minute:
				is_between = true;
		elif value.min.minute <= game_time.minute <= value.max.minute:
			is_between = true;
	return is_between;

func get_action_by_id(action_id: String) -> Action:
	return _actions.get(action_id);
	
	
func _check_hunger(validator_data: Dictionary, owner_id: String) -> bool:
	var alive: Alive = AlivesController.get_alive_by_owner_id(owner_id);
	return _check_value_between_incl(alive.alive_status.hunger.value, validator_data.value.min, validator_data.value.max);
	
func _check_merchant(validator_data: Dictionary, owner_id: String) -> bool:
	var alive: Alive = AlivesController.get_alive_by_owner_id(owner_id);
	return _check_has_property(alive, "is_merchant") and _check_value_match(alive.is_merchant, validator_data.value);


func _check_game_time(validator_data: Dictionary, owner_id: String) -> bool:
	return _is_game_time_between_value(last_game_time, validator_data.value);

# Helpers functions to check -> next put this in something like ValidatorUtils files
func _check_value_between_incl(value: int, min: int, max: int) -> bool:
	return value >= min and value <= max;
	
func _check_value_match(value, expected) -> bool:
	return value == expected;

func _check_has_property(obj: Object, expected: String) -> bool:
	return expected in obj;
