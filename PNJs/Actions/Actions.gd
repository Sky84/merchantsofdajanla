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
	var alive: Alive = AlivesController.get_alive_by_owner_id(owner_id);
	for condition in conditions:
		if condition.type == "Hunger":
			if alive._alive_status.hunger.value > condition.value:
				return false;
			# Ajouter un if si conditions complémentaire Ex. hunger and at home
		if condition.type == "isMerchant":
			if !("is_merchant" in alive) or alive.is_merchant != condition.value:
				return false;
		if condition.type == "GameTime":
			if !_is_game_time_between_value(last_game_time, condition.value):
				return false;
	return true; # Si toutes les conditions sont satisfaites

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
