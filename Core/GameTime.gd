class_name GameTime

var _hour: int;
var _minute: int;

var hour: int:
	get:
		return _hour;
		
var minute: int:
	get:
		return _minute;

func _init(__hour: int, __minute: int):
	_hour = __hour;
	_minute = __minute;

func duplicate(game_time: GameTime) -> GameTime:
	return GameTime.new(game_time._hour, game_time._minute);

func as_dictionary() -> Dictionary:
	return {
		'hour': _hour,
		'minute': _minute
	};

func is_between_incl(_min: Dictionary, _max: Dictionary) -> bool:
	var min_time = GameTime.new(_min.hour, _min.minute);
	var max_time = GameTime.new(_max.hour, _max.minute);
	if min_time._is_greater_or_equal_than(max_time):
		return _is_greater_or_equal_than(min_time) or _is_lower_or_equal_than(max_time);
	return _is_greater_or_equal_than(min_time) and _is_lower_or_equal_than(max_time);

func to_formated() -> String:
	return str(_hour).pad_zeros(2) + ':' + str(_minute).pad_zeros(2);

func update() -> void:
	var tmp = duplicate(self);
	_minute = (_minute + 1) % 60;
	if tmp._minute == 59 and _minute == 0:
		_hour = (_hour + 1) % 24;

#private functions
func _is_equal_to(other: GameTime) -> bool:
	return _hour == other.hour and _minute == other.minute;

func _is_greater_than(other: GameTime) -> bool:
	if _hour < other.hour:
		return false;
	elif _hour > other.hour:
		return true;
	return _minute > other.minute;
		
func _is_midnight() -> bool:
	return _hour == 0;

func _is_greater_or_equal_than(other: GameTime) -> bool:
	return _is_greater_than(other) or _is_equal_to(other);

func _is_lower_than(other: GameTime) -> bool:
	if _hour < other.hour:
		return true;
	elif _hour > other.hour:
		return false;
	return _minute < other.minute;

func _is_lower_or_equal_than(other: GameTime) -> bool:
	return _is_lower_than(other) or _is_equal_to(other);
