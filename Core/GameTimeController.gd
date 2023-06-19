extends DirectionalLight3D

@export_range(0, 24) var _start_hour_game_time: int;
@export_range(0, 59) var _start_minute_game_time: int;

@onready var timer = $Timer;

@onready var _game_time: GameTime = GameTime.new(_start_hour_game_time, _start_minute_game_time);

func _ready():
	_emit_update();

func _on_timer_timeout():
	_game_time.update();
	_emit_update();

func _emit_update():
	GameTimeEvents.on_game_time_changed.emit(_game_time);
	GameTimeEvents.on_formatted_game_time_changed.emit(_game_time.to_formated());
