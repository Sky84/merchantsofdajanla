extends Alive
class_name Player
@onready var ui_controller: UIController = %CanvasLayer;

var _is_inventory_visible = false;

var equipment;
var status;
var attack;

# Called when the node enters the scene tree for the first time.
func _ready():
	super();
	_is_player = true;
	PlayerEvents.on_item_in_hand_changed.connect(_on_item_in_hand_changed);
	PlayerEvents.on_player_block.connect(func (value: bool): _is_blocked = value; is_busy = value);
	status = preload("res://Player/Components/PlayerStatus.gd").new();
	status.name = "Status";
	add_child(status);
	equipment = preload("res://Player/Components/PlayerEquipment.gd").new();
	equipment.name = "Equipment";
	add_child(equipment);
	attack = preload("res://Player/Components/PlayerAttack.gd").new();
	attack.name = "Attack";
	add_child(attack);
	status.notify_changed.call_deferred();

func equip(item_id: String) -> void:
	equipment.equip(item_id);

func unequip(slot: String) -> void:
	equipment.unequip(slot);

func is_equipped(slot: String) -> bool:
	return equipment.is_equipped(slot);

func take_damage(amount: int, source = null) -> void:
	super.take_damage(amount, source);
	status.notify_changed();

func die() -> void:
	status.die();

func respawn() -> void:
	status.respawn();

func consume(item: Dictionary, notify: bool = false) -> void:
	super(item, notify);
	status.notify_changed();

func _input(event):
	if _is_blocked:
		return;
	if event is InputEventKey:
		if event.is_action_released("TAB"):
			_is_inventory_visible = !_is_inventory_visible;
			InventoryEvents.visibility_inventory.emit(_is_inventory_visible);
		if event.is_action_released("use"):
			_is_inventory_visible = false;
			if _nearest_interactive != null:
				_nearest_interactive.interact(_owner_id);
	if Input.is_action_just_released("interract_with_item_in_hand") and GameItems.is_consomable(_item_in_hand):
		consume(_item_in_hand);

func _handle_movement():
	var direction_x = Input.get_action_strength("right") - Input.get_action_strength("left");
	var direction_z = Input.get_action_strength("down") - Input.get_action_strength("up");
	var speed_run = max(1, Input.get_action_strength("run") * speed_run_factor);
	var speed = (speed_walk / _speed_walk_factor) * speed_run;
	if _is_blocked:
		speed = 0;
	velocity = Vector3(direction_x, 0, direction_z).normalized() * speed;

func _handle_animation():
	super();
	var state = get_state();
	animation_tree.set("parameters/conditions/isAttacking", state.is_attacking);

func get_state() -> Dictionary:
	var state = super();
	var player_state = {
		"is_attacking": Input.get_action_strength("attack") \
			and attack != null \
			and attack.has_equipped_weapon()
	};
	player_state.merge(state);
	return player_state;
