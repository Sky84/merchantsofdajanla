extends DirectionalLight3D

@export_range(0, 24) var _start_hour_game_time: int;
@export_range(0, 59) var _start_minute_game_time: int;

@onready var timer = $Timer;

@onready var hour: int = _start_hour_game_time;
@onready var minute: int = _start_minute_game_time;

func _ready():
	GameTimeEvents.on_game_time_changed.emit({
		"hour": hour,
		"minute": minute
	});
	GameTimeEvents.on_formatted_game_time_changed.emit(_formatted_game_time());

func _on_timer_timeout():
	var old_minute = minute;
	minute = (minute + 1) % 60;
	
	if(old_minute == 59 and minute == 0):
		hour = (hour + 1) % 24;
	GameTimeEvents.on_formatted_game_time_changed.emit(_formatted_game_time());
	GameTimeEvents.on_game_time_changed.emit({
		"hour": hour,
		"minute": minute
	});

func _formatted_game_time():
	return str(hour).pad_zeros(2)+ ':'+ str(minute).pad_zeros(2);
