extends Node

const KNOCKBACK_FORCE := 8.0;
const KNOCKBACK_DECAY := 30.0;

static func apply_damage(target, amount: int, source = null) -> void:
	if target.get("is_dead"):
		return;
	var stat = target.alive_status.health;
	stat.value = clampi(stat.value - amount, 0, stat.max);
	for sprite in _sprites_of(target):
		var tween = target.create_tween();
		tween.tween_property(sprite, "modulate", Color(2.5, 0.4, 0.4), 0.05);
		tween.tween_property(sprite, "modulate", sprite.modulate, 0.2);
	spawn_damage_label(target, amount);
	if source != null and source is Node3D:
		var dir = (target.global_position - source.global_position).normalized();
		target._knockback = Vector3(dir.x, 0, dir.z) * KNOCKBACK_FORCE;
	if stat.value <= 0 and target.has_method("die"):
		target.die();

static func apply_knockback(target, delta: float) -> void:
	target.velocity += target._knockback;
	target._knockback = target._knockback.move_toward(Vector3.ZERO, delta * KNOCKBACK_DECAY);

static func spawn_damage_label(target, amount: int) -> void:
	var label = Label3D.new();
	label.text = "-" + str(amount);
	label.modulate = Color(1, 0.25, 0.25);
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED;
	label.pixel_size = 0.005;
	label.font_size = 48;
	target.get_parent().add_child(label);
	label.global_position = target.global_position + Vector3(0, 1.8, 0);
	var tween = target.create_tween();
	tween.set_parallel();
	tween.tween_property(label, "global_position:y", label.global_position.y + 1.2, 0.8);
	tween.tween_property(label, "modulate:a", 0.0, 0.8);
	tween.chain().tween_callback(label.queue_free);

static func _sprites_of(target) -> Array:
	return target.find_children("*", "AnimatedSprite3D", true, false);
