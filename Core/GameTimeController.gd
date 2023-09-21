extends DirectionalLight3D

@export_range(0, 24) var _start_hour_game_time: int;
@export_range(0, 59) var _start_minute_game_time: int;
@export var gradient_day_night: GradientTexture1D;
@export var sun_density: Curve;
@export var world_environment: WorldEnvironment;

@onready var timer = $Timer;

@onready var _game_time: GameTime = GameTime.new(_start_hour_game_time, _start_minute_game_time);

func _ready():
	_emit_update();

func _on_timer_timeout():
	var texture_width = gradient_day_night.get_width();
	var current_day_minutes: float = (_game_time.hour * 60.0) + _game_time.minute;
	var total_day_minutes: float = 24.0 * 60.0;
	var current_day_percentage: float = current_day_minutes / total_day_minutes;
	var color_index: float = current_day_percentage * (texture_width);
	light_color = Color(gradient_day_night.get_image().get_pixel(color_index, 0));
	rotation_degrees.x = (current_day_percentage * 360.0) + 90.0;
	world_environment.environment.ambient_light_color = light_color;
	world_environment.environment.ambient_light_energy = sun_density.sample(current_day_percentage);
	_game_time.update();
	_emit_update();

func _emit_update():
	GameTimeEvents.on_game_time_changed.emit(_game_time);
	GameTimeEvents.on_formatted_game_time_changed.emit(_game_time.to_formated());
