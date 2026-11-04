extends CharacterBody3D
class_name HostileController

const Combat = preload("res://Core/Combat.gd");
const OcclusionSilhouette = preload("res://Core/OcclusionSilhouette.gd");

@export var species_id := "sawaji";
@export var speed := 4.0; # entre marche (3) et course (6) du joueur
@export var aggro_range := 8.0;
@export var lose_interest_range := 12.0;
@export var attack_range := 2.5;
@export var attack_damage := 10;
@export var attack_cooldown := 1.0;
@export var wander_interval := 6.0;
@export var wander_range := 8.0;
@export var wander_speed_ratio := 0.5;
@export var tint: Color = Color.WHITE;
@export var tint_random := 0.08;
@export var same_species_aggression_chance := 0.0;
@export var max_health := 60;

const SPRITES := {
	"idle": "res://PNJs/Sawaji/sawaji_idle.png",
	"walk": "res://PNJs/Sawaji/sawaji_walk.png",
	"attack": "res://PNJs/Sawaji/sawaji_attack.png",
};
const VARIANTS := ["", "_beige", "_marron", "_gris", "_noir", "_creme"];
@export var variant := ""; # "" = aléatoire
const FRAME_SIZE := Vector2(64, 32);

var alive_status := {"health": {"value": 60, "max": 60}};
var is_dead := false;
var _owner_id := "";
var _target = null;
var _cooldown := 0.0;
var _knockback := Vector3.ZERO;
var _home_position = null;
var _wander_target: Vector3;
var _wander_timer := randf() * 6.0;
var _aggressive_to_own := false;

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
	_aggressive_to_own = randf() < same_species_aggression_chance;
	OcclusionSilhouette.attach(self);

func _process(delta: float) -> void:
	if is_dead:
		return;
	_cooldown = max(0.0, _cooldown - delta);
	if not _is_valid_target(_target):
		_target = _find_target();
	if _target == null:
		_wander(delta);
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
		sprite.flip_h = velocity.x > 0;
	Combat.apply_knockback(self, delta);
	move_and_slide();
	_update_animation();

func _wander(delta: float) -> void:
	if _home_position == null:
		_home_position = global_position;
		_wander_target = global_position;
	_wander_timer -= delta;
	if _wander_timer <= 0.0:
		_wander_timer = wander_interval + randf() * wander_interval;
		_wander_target = _home_position + Vector3(
			randf_range(-wander_range, wander_range), 0, randf_range(-wander_range, wander_range));
	if global_position.distance_to(_wander_target) > 1.0:
		var dir = (_wander_target - global_position).normalized();
		velocity = Vector3(dir.x, 0, dir.z) * speed * wander_speed_ratio;
		sprite.flip_h = velocity.x > 0;
	else:
		velocity = Vector3.ZERO;
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
	if alive.get("species_id") != species_id:
		return true;
	return _aggressive_to_own;

func _attack() -> void:
	_cooldown = attack_cooldown;
	sprite.play("attack");
	_knockback = (_target.global_position - global_position).normalized() * 8.0;
	if _is_valid_target(_target) and _target.has_method("take_damage"):
		_target.take_damage(attack_damage, self);

func take_damage(amount: int, source = null) -> void:
	Combat.apply_damage(self, amount, source);

func die() -> void:
	is_dead = true;
	velocity = Vector3.ZERO;
	sprite.play("idle");
	$CollisionShape3D.disabled = true;
	var tween = create_tween();
	tween.set_parallel();
	tween.tween_property(sprite, "rotation_degrees", Vector3(0, 0, 90), 0.4);
	tween.tween_property(sprite, "modulate", sprite.modulate * Color(0.7, 0.65, 0.6), 0.6);
	tween.chain().tween_callback(func(): set_process(false));

func _update_animation() -> void:
	if sprite.animation == &"attack" and sprite.is_playing():
		return;
	sprite.play(&"idle" if velocity.length() < 1.0 else &"walk");

func _build_sprite_frames() -> void:
	if variant == "":
		variant = VARIANTS[randi() % VARIANTS.size()];
	var frames = SpriteFrames.new();
	for anim in SPRITES:
		var path = SPRITES[anim].replace(".png", "%s.png" % variant);
		var tex: Texture2D = load(path if ResourceLoader.exists(path) else SPRITES[anim]);
		frames.add_animation(anim);
		frames.set_animation_speed(anim, 8.0);
		frames.set_animation_loop(anim, anim != "attack");
		for i in tex.get_width() / FRAME_SIZE.x:
			var atlas = AtlasTexture.new();
			atlas.atlas = tex;
			atlas.region = Rect2(i * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y);
			frames.add_frame(anim, atlas);
	sprite.sprite_frames = frames;
