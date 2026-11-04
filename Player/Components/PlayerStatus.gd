extends Node

const HUNGER_DECAY_INTERVAL := 15; # game minutes per -1 hunger
const STARVE_DAMAGE_INTERVAL := 30; # game minutes per -1 health when starving
var _tick_counter := 0;

@onready var _player = get_parent();

func _ready() -> void:
	GameTimeEvents.on_game_time_changed.connect(_on_game_time_tick);
	PlayerEvents.respawn.connect(respawn);

func _on_game_time_tick(_game_time) -> void:
	_tick_counter += 1;
	if _tick_counter % HUNGER_DECAY_INTERVAL == 0:
		_change_stat("hunger", -1);
	if _player.alive_status.hunger.value <= 0 and _tick_counter % STARVE_DAMAGE_INTERVAL == 0:
		_player.take_damage(1);

func _change_stat(key: String, delta: int) -> void:
	var stat = _player.alive_status[key];
	stat.value = clampi(stat.value + delta, 0, stat.max);
	notify_changed();

func notify_changed() -> void:
	PlayerEvents.player_status_changed.emit(_player.alive_status);

func die() -> void:
	_player.is_dead = true;
	_player._is_blocked = true;
	_player.velocity = Vector3.ZERO;
	PlayerEvents.player_died.emit();

func respawn() -> void:
	_player.is_dead = false;
	_player._is_blocked = false;
	_player.alive_status.health.value = _player.alive_status.health.max;
	_player.alive_status.hunger.value = _player.alive_status.hunger.max;
	_player.global_position = Vector3(0, 0, 0);
	notify_changed();
