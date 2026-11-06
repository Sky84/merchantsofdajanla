extends Resource
class_name WeaponHoldProfile

@export var idle_offsets: Array[Vector2] = [];
@export var walk_offsets: Array[Vector2] = [];
@export var run_offsets: Array[Vector2] = [];
@export var sit_offsets: Array[Vector2] = [];
@export var attack_offsets: Array[Vector2] = [];

func get_offset(animation: StringName, frame: int) -> Vector2:
	var offsets: Array[Vector2];
	match animation:
		&"idle":
			offsets = idle_offsets;
		&"walk":
			offsets = walk_offsets;
		&"run":
			offsets = run_offsets;
		&"sit":
			offsets = sit_offsets;
		&"hit":
			offsets = attack_offsets;
		_:
			return Vector2.ZERO;
	if offsets.is_empty():
		return Vector2.ZERO;
	return offsets[clampi(frame, 0, offsets.size() - 1)];
