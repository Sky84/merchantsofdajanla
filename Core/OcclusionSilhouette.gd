extends Node

const SILHOUETTE_COLOR := Color(0.0, 0.0, 0.0, 0.35);

# Crée un sprite fantôme no_depth_test pour chaque AnimatedSprite3D sous root.
# Retourne un dict {sprite: silhouette} à passer à sync() chaque frame.
static func add(root: Node3D) -> Dictionary:
	var pairs := {};
	for sprite in root.find_children("*", "AnimatedSprite3D", true, false):
		var sil = AnimatedSprite3D.new();
		sil.pixel_size = sprite.pixel_size;
		sil.billboard = sprite.billboard;
		sil.texture_filter = sprite.texture_filter;
		sil.position = sprite.position;
		sil.scale = sprite.scale;
		sil.offset = sprite.offset;
		sil.modulate = SILHOUETTE_COLOR;
		sil.no_depth_test = true;
		sil.cast_shadow = 0;
		sil.shaded = false;
		sprite.get_parent().add_child(sil);
		sil.sprite_frames = sprite.sprite_frames;
		pairs[sprite] = sil;
	return pairs;

static func sync(pairs: Dictionary) -> void:
	for sprite in pairs:
		var sil = pairs[sprite];
		if not is_instance_valid(sil):
			continue;
		sil.sprite_frames = sprite.sprite_frames;
		sil.animation = sprite.animation;
		sil.frame = sprite.frame;
		sil.flip_h = sprite.flip_h;
		sil.visible = sprite.visible;
