extends Node

# Action Ids
const EAT: String = 'Eat';
const BUY: String = 'Buy';
const WAIT: String = 'Wait';
const LEAVE_CURRENT_BUILDING: String = 'LeaveCurrentBuilding';

var _triggers := {};
var _actions := {};

var _triggers_json_path = 'AI/Triggers.json';
var _actions_json_path = 'AI/Actions.json';
var _actions_path = 'res://PNJs/Actions/';
var _actions_path_suffix = 'Action.gd';

var last_game_time: GameTime = GameTime.new(0, 0);

signal actions_ready;
signal triggers_ready;

# Called when the node enters the scene tree for the first time.
func _ready():
	NavigationEvents.on_game_scene_ready.connect(_init_actions);

func _init_actions():
	GameTimeEvents.on_game_time_changed.connect(func(game_time: GameTime): last_game_time = game_time);
	_triggers = JsonResourceLoader.load_json(_triggers_json_path);
	var actions_from_json = JsonResourceLoader.load_json(_actions_json_path);
	for action_json in actions_from_json:
		var action: Action = create_action(action_json);
		_actions[action.id] = action;
	actions_ready.emit();
	triggers_ready.emit();

func create_action(action: Dictionary) -> Action:
	var instance_action_class: GDScript = load(_actions_path+action.id+_actions_path_suffix) as GDScript;
	return instance_action_class.new(action.id, action.target, action.params);

func get_action_id_by_triggers(owner_id: String) -> String:
	if _triggers.is_empty():
		await triggers_ready;
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

func get_action_by_id(action_id: String) -> Action:
	if _actions.is_empty():
		await actions_ready;
	var action: Action = _actions.get(action_id);
	return create_action({"id": action.id, "target": action.target, "params": action.params});

func _check_hunger(validator_data: Dictionary, owner_id: String) -> bool:
	var alive: Alive = AlivesController.get_alive_by_owner_id(owner_id);
	return _check_value_between_incl(alive.alive_status.hunger.value, validator_data.value.min, validator_data.value.max);
	
func _check_merchant(validator_data: Dictionary, owner_id: String) -> bool:
	var alive: Alive = AlivesController.get_alive_by_owner_id(owner_id);
	return _check_has_property(alive, "is_merchant") and _check_value_match(alive.is_merchant, validator_data.value);


func _check_game_time(validator_data: Dictionary, _owner_id: String) -> bool:
	return last_game_time.is_between_incl(validator_data.value.min, validator_data.value.max);

# Helpers functions to check -> next put this in something like ValidatorUtils files
func _check_value_between_incl(value: int, _min: int, _max: int) -> bool:
	return value >= _min and value <= _max;
	
func _check_value_match(value, expected) -> bool:
	return value == expected;

func _check_has_property(obj: Object, expected: String) -> bool:
	return expected in obj;
