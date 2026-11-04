extends Node

# A separate render pass, never a physics obstacle or a displaced copy.
const SHADER = preload("res://Core/OcclusionSilhouette.gdshader");
const PASS_META := &"occlusion_pass";
var _pairs: Dictionary = {};

static func attach(root: Node3D) -> void:
	if root.has_node("OcclusionSilhouette"):
		return;
	var effect = new();
	effect.name = "OcclusionSilhouette";
	root.add_child(effect);
	effect.process_priority = 100; # After AnimationTree and cloth synchronization.
	for sprite in root.find_children("*", "AnimatedSprite3D", true, false):
		if sprite.has_meta(PASS_META) or "Weapons" in sprite.name:
			continue;
		var silhouette = AnimatedSprite3D.new();
		silhouette.name = "OcclusionPass";
		silhouette.set_meta(PASS_META, true);
		silhouette.visible = false;
		silhouette.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;
		var material = ShaderMaterial.new();
		material.shader = SHADER;
		# Trees have an alpha prepass and a transparent color pass (priority 0).
		material.render_priority = 100;
		silhouette.material_override = material;
		sprite.get_parent().add_child(silhouette);
		effect._pairs[sprite] = silhouette;
	effect._process(0.0);

func _process(_delta: float) -> void:
	var dead = get_parent().get("is_dead") == true;
	for sprite in _pairs.keys():
		var silhouette: AnimatedSprite3D = _pairs[sprite];
		if not is_instance_valid(sprite):
			silhouette.queue_free();
			_pairs.erase(sprite);
			continue;
		var frames: SpriteFrames = sprite.sprite_frames;
		silhouette.visible = not dead and sprite.is_visible_in_tree() and frames != null;
		if not silhouette.visible or not frames.has_animation(sprite.animation):
			continue;
		var texture = frames.get_frame_texture(sprite.animation, sprite.frame);
		if texture == null:
			silhouette.visible = false;
			continue;
		silhouette.transform = sprite.transform;
		silhouette.pixel_size = sprite.pixel_size;
		silhouette.billboard = sprite.billboard;
		silhouette.axis = sprite.axis;
		silhouette.centered = sprite.centered;
		silhouette.offset = sprite.offset;
		silhouette.sprite_frames = frames;
		silhouette.animation = sprite.animation;
		silhouette.set_frame_and_progress(sprite.frame, sprite.frame_progress);
		silhouette.flip_h = sprite.flip_h;
		silhouette.flip_v = sprite.flip_v;
		silhouette.layers = sprite.layers;
		# AnimatedSprite3D already generates UVs for the current atlas region.
		# Bind the atlas itself; a spatial shader has no built-in TEXTURE.
		if texture is AtlasTexture:
			texture = texture.atlas;
		var material: ShaderMaterial = silhouette.material_override;
		material.set_shader_parameter("frame_atlas", texture);
		material.set_shader_parameter("billboard_mode", sprite.billboard);
