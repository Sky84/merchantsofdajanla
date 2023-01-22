extends Node2D

@onready var skin_animated_sprite_2d = $"../SkinAnimatedSprite2D";

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var current_animation_name = skin_animated_sprite_2d.animation;
	var clothes_animated_sprites: Array = get_children();
	for animated_sprite in clothes_animated_sprites:
		animated_sprite.frame = skin_animated_sprite_2d.frame;
		if animated_sprite.animation != current_animation_name:
			animated_sprite.animation = current_animation_name;
			animated_sprite.scale.x = skin_animated_sprite_2d.scale.x;
