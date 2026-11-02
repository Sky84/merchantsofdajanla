extends CharacterBody3D
class_name HostileController

@export var species_id := "sawaji";
@export var speed := 4.0; # entre marche (3) et course (6) du joueur
@export var aggro_range := 8.0;
@export var lose_interest_range := 12.0;
@export var attack_range := 2.5;
@export var attack_damage := 10;
@export var attack_cooldown := 1.0;
@export var tint: Color = Color.WHITE;
@export var tint_random := 0.08;
@export var max_health := 60;

const SPRITES := {
	"idle": "res://PNJs/Sawaji/sawaji_idle.png",
	"walk": "res://PNJs/Sawaji/sawaji_walk.png",
	"attack": "res://PNJs/Sawaji/sawaji_attack.png",
};
const FRAME_SIZE := Vector2(64, 32);

var alive_status := {"health": {"value": 60, "max": 60}};
var is_dead := false;
var _owner_id := "";
var _target = null;
var _cooldown := 0.0;
var _knockback := Vector3.ZERO;

@onready var sprite = $AnimatedSprite3D;

func _ready() -> void:
	add_to_group(Alive.GROUP_NAME);
	_owner_id = name + str(global_position.floor());
	alive_status.health.value = max_health;
	alive_status.health.max = max_health;
	_build_sprite_frames();
	sprite.play("idle");
	sprite.modulate = tint * Color(
		1 + randf_range(-tint_random, tint_random),
		1 + randf_range(-tint_random, tint_random),
		1 + randf_range(-tint_random, tint_random));

func _process(delta: float) -> void:
	if is_dead:
		return;
	_cooldown = max(0.0, _cooldown - delta);
	if not _is_valid_target(_target):
		_target = _find_target();
	if _target == null:
		velocity = Vector3.ZERO;
	elif global_position.distance_to(_target.global_position) > lose_interest_range:
		_target = null;
		velocity = Vector3.ZERO;
	elif global_position.distance_to(_target.global_position) <= attack_range:
		velocity = Vector3.ZERO;
		if _cooldown <= 0:
			_attack();
	else:
		var dir = (_target.global_position - global_position).normalized();
		velocity = Vector3(dir.x, 0, dir.z) * speed;
		sprite.scale.x = -1 if velocity.x < 0 else 1;
	velocity += _knockback;
	_knockback = _knockback.move_toward(Vector3.ZERO, delta * 30.0);
	move_and_slide();
	_update_animation();

func _is_valid_target(alive) -> bool:
	return alive != null and is_instance_valid(alive) and not alive.get("is_dead");

func _find_target():
	var nearest = null;
	var nearest_dist = aggro_range;
	for alive in get_tree().get_nodes_in_group(Alive.GROUP_NAME):
		if alive == self or not _is_valid_target(alive) or not is_hostile_to(alive):
			continue;
		var dist = global_position.distance_to(alive.global_position);
		if dist < nearest_dist:
			nearest = alive;
			nearest_dist = dist;
	return nearest;

func is_hostile_to(alive) -> bool:
	return alive.get("species_id") != species_id;

func _attack() -> void:
	_cooldown = attack_cooldown;
	sprite.play("attack");
	_knockback = (_target.global_position - global_position).normalized() * 8.0;
	if _is_valid_target(_target) and _target.has_method("take_damage"):
		_target.take_damage(attack_damage, self);

func take_damage(amount: int, source = null) -> void:
	if is_dead:
		return;
	alive_status.health.value = clampi(alive_status.health.value - amount, 0, alive_status.health.max);
	var tween = create_tween();
	tween.tween_property(sprite, "modulate", Color(2.5, 0.4, 0.4), 0.05);
	tween.tween_property(sprite, "modulate", sprite.modulate, 0.2);
	_spawn_damage_label(amount);
	if source != null and source is Node3D:
		var dir = (global_position - source.global_position).normalized();
		_knockback = Vector3(dir.x, 0, dir.z) * 8.0;
	if alive_status.health.value <= 0:
		die();

func _spawn_damage_label(amount: int) -> void:
	var label = Label3D.new();
	label.text = "-" + str(amount);
	label.modulate = Color(1, 0.25, 0.25);
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED;
	label.pixel_size = 0.005;
	label.font_size = 48;
	get_parent().add_child(label);
	label.global_position = global_position + Vector3(0, 1.2, 0);
	var tween = create_tween();
	tween.set_parallel();
	tween.tween_property(label, "global_position:y", label.global_position.y + 1.2, 0.8);
	tween.tween_property(label, "modulate:a", 0.0, 0.8);
	tween.chain().tween_callback(label.queue_free);

func die() -> void:
	is_dead = true;
	velocity = Vector3.ZERO;
	sprite.play("idle");
	var tween = create_tween();
	tween.set_parallel();
	tween.tween_property(sprite, "rotation_degrees", Vector3(0, 0, 90), 0.4);
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5).set_delay(0.3);
	tween.chain().tween_callback(queue_free);

func _update_animation() -> void:
	if sprite.animation == &"attack" and sprite.is_playing():
		return;
	sprite.play(&"idle" if velocity.length() < 1.0 else &"walk");

func _build_sprite_frames() -> void:
	var frames = SpriteFrames.new();
	for anim in SPRITES:
		var tex: Texture2D = load(SPRITES[anim]);
		frames.add_animation(anim);
		frames.set_animation_speed(anim, 8.0);
		frames.set_animation_loop(anim, anim != "attack");
		for i in tex.get_width() / FRAME_SIZE.x:
			var atlas = AtlasTexture.new();
			atlas.atlas = tex;
			atlas.region = Rect2(i * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y);
			frames.add_frame(anim, atlas);
	sprite.sprite_frames = frames;
