extends AnimatedSprite3D
class_name WeaponAttachment3D

@export var source_sprite_path: NodePath;
@export var hold_profile: WeaponHoldProfile;

@onready var _source: AnimatedSprite3D = get_node(source_sprite_path);
@onready var _base_scale := scale;

func _ready() -> void:
	sync_to_source();

func _process(_delta: float) -> void:
	sync_to_source();

# This component depends only on an AnimatedSprite3D source, so NPCs and
# hostiles can reuse it without depending on PlayerEquipment.
func sync_to_source() -> void:
	if _source == null or sprite_frames == null:
		return;
	var source_animation := _source.animation;
	if not sprite_frames.has_animation(source_animation):
		return;
	animation = source_animation;
	var weapon_frames := sprite_frames.get_frame_count(source_animation);
	if weapon_frames > 0:
		frame = mini(_source.frame, weapon_frames - 1);
	scale.x = absf(_base_scale.x) * signf(_source.scale.x);
	offset = hold_profile.get_offset(source_animation, _source.frame) \
		if hold_profile != null else Vector2.ZERO;
