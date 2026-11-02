extends Alive
class_name Player
@onready var ui_controller: UIController = %CanvasLayer;

var _is_inventory_visible = false;

const HUNGER_DECAY_INTERVAL := 15; # game minutes per -1 hunger
const STARVE_DAMAGE_INTERVAL := 30; # game minutes per -1 health when starving
var _tick_counter := 0;

const EQUIP_SLOT_NODES := {"shirt": "ShirtsAnimatedSprite3D", "pants": "PantsAnimatedSprite3D", "weapon": "WeaponsAnimatedSprite3D"};
const DEFAULT_EQUIP_ITEMS := {"shirt": "shirt_basic", "pants": "pants_basic", "weapon": "sword_basic"};
var _equipped_items := {};

# Called when the node enters the scene tree for the first time.
func _ready():
	super();
	_is_player = true;
	PlayerEvents.on_item_in_hand_changed.connect(_on_item_in_hand_changed);
	PlayerEvents.on_player_block.connect(func (value: bool): _is_blocked = value; is_busy = value);
	GameTimeEvents.on_game_time_changed.connect(_on_game_time_tick);
	PlayerEvents.equip_item_requested.connect(func(item_id): equip(item_id));
	PlayerEvents.respawn.connect(respawn);
	for slot in EQUIP_SLOT_NODES:
		var layer = $ClothAnimations.get_node_or_null(EQUIP_SLOT_NODES[slot]);
		if layer != null and layer.sprite_frames != null:
			_equipped_items[slot] = DEFAULT_EQUIP_ITEMS[slot];
	PlayerEvents.player_status_changed.emit.call_deferred(alive_status);

func equip(item_id: String) -> void:
	var item = GameItems._items.get(item_id);
	if item == null or item.get("type") != "Equipment" or not item.has("slot"):
		return;
	var slot = item["slot"];
	var layer = $ClothAnimations.get_node_or_null(EQUIP_SLOT_NODES[slot]);
	if layer == null:
		return;
	if _equipped_items.has(slot):
		unequip(slot);
	layer.sprite_frames = load(item["sprite_frames"]);
	layer.visible = true;
	_equipped_items[slot] = item_id;
	var container_ids = ContainersController.get_container_ids_by_owner_id(_owner_id);
	if not ContainersController.find_item_in_containers(container_ids, item_id).is_empty():
		ContainersController.remove_item(container_ids, item_id, 1);
	PlayerEvents.equipment_changed.emit();

func unequip(slot: String) -> void:
	if not _equipped_items.has(slot) or not _has_empty_slot():
		return;
	var item_id = _equipped_items[slot];
	var layer = $ClothAnimations.get_node_or_null(EQUIP_SLOT_NODES[slot]);
	layer.visible = false;
	_equipped_items.erase(slot);
	ContainersController.add_item(ContainersController.get_container_ids_by_owner_id(_owner_id), item_id, 1);
	PlayerEvents.equipment_changed.emit();

func _has_empty_slot() -> bool:
	for cid in ContainersController.get_container_ids_by_owner_id(_owner_id):
		var slots = ContainersController.get_container_data(cid);
		for x in slots:
			for y in slots[x]:
				if slots[x][y].is_empty():
					return true;
	return false;

func is_equipped(slot: String) -> bool:
	return _equipped_items.has(slot);

func _on_game_time_tick(_game_time) -> void:
	_tick_counter += 1;
	if _tick_counter % HUNGER_DECAY_INTERVAL == 0:
		_change_stat("hunger", -1);
	if alive_status.hunger.value <= 0 and _tick_counter % STARVE_DAMAGE_INTERVAL == 0:
		take_damage(1);

func _change_stat(key: String, delta: int) -> void:
	var stat = alive_status[key];
	stat.value = clampi(stat.value + delta, 0, stat.max);
	PlayerEvents.player_status_changed.emit(alive_status);

func take_damage(amount: int, source = null) -> void:
	super.take_damage(amount, source);
	PlayerEvents.player_status_changed.emit(alive_status);

func die() -> void:
	is_dead = true;
	_is_blocked = true;
	velocity = Vector3.ZERO;
	PlayerEvents.player_died.emit();

func respawn() -> void:
	is_dead = false;
	_is_blocked = false;
	alive_status.health.value = alive_status.health.max;
	alive_status.hunger.value = alive_status.hunger.max;
	global_position = Vector3(0, 0, 0);
	PlayerEvents.player_status_changed.emit(alive_status);

func consume(item: Dictionary, notify: bool = false) -> void:
	super(item, notify);
	PlayerEvents.player_status_changed.emit(alive_status);

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

const ATTACK_RANGE := 2.0;
const ATTACK_DAMAGE := 12;
const ATTACK_COOLDOWN := 0.8;
var _attack_cooldown := 0.0;

func _process(delta) -> void:
	super._process(delta);
	_attack_cooldown = max(0.0, _attack_cooldown - delta);
	if Input.is_action_just_pressed("attack") and not _is_blocked and not is_dead:
		_attack();

func _attack() -> void:
	_attack_cooldown = ATTACK_COOLDOWN;
	for alive in get_tree().get_nodes_in_group(Alive.GROUP_NAME):
		if alive == self or not is_instance_valid(alive) or alive.get("is_dead"):
			continue;
		if global_position.distance_to(alive.global_position) <= ATTACK_RANGE:
			alive.take_damage(ATTACK_DAMAGE, self);

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
			and ui_controller.get_current_mouse_target() == null \
			and GameItems.is_tool_or_weapon(_item_in_hand)
	};
	player_state.merge(state);
	return player_state;
