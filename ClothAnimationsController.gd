extends Node3D

@onready var skins_animated_sprite_3d = $SkinsAnimatedSprite3D;
@onready var clothes_animated_sprites: Array = get_children();

const clothes_type_name: String = 'AnimatedSprite3D';

const CLOTH_NAMES = {
	SKINS = 'Skins',
	HAIRS = 'Hairs',
	SHIRTS = 'Shirts',
	PANTS = 'Pants'
}

# set in runtime to be Ex. {HairsAnimatedSprite3D: 0}
var clothes_map_indexes = {};

func _ready():
	for cloth_name in CLOTH_NAMES:
		var cloth_scene_name = CLOTH_NAMES[cloth_name]+clothes_type_name;
		var cloth_scene = get_node(cloth_scene_name);
		if cloth_scene:
			clothes_map_indexes[cloth_scene_name] = 0;
			change_cloth_by_index(CLOTH_NAMES[cloth_name], clothes_map_indexes[cloth_scene_name]);

func change_cloth_by_index(cloth_name: String, index: int):
	var cloth_scene_name = cloth_name+clothes_type_name;
	if clothes_map_indexes.has(cloth_scene_name):
		clothes_map_indexes[cloth_scene_name] = index;
		var sprite_name = cloth_name.replace(clothes_type_name, '')+'_'+str(index);
		_get_cloth_scene_by_name(cloth_scene_name).frames = load('res://Player/SpriteFrames/'+sprite_name+'.tres');
		return;
	printerr('change_cloth_by_index:: '+str(index)+' for '+cloth_scene_name+' dont exist in clothes_map_indexes')
	printerr('change_cloth_by_index::clothes_map_indexes '+ JSON.stringify(clothes_map_indexes))

func _get_cloth_scene_by_name(cloth_name: String) -> AnimatedSprite3D:
	for cloth in clothes_animated_sprites:
		if cloth.name == cloth_name:
			return cloth;
	printerr('_get_cloth_scene_by_name:: '+cloth_name+'dont exist in clothes_animated_sprites');
	return null;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var current_animation_name = skins_animated_sprite_3d.animation;
	for animated_sprite in clothes_animated_sprites:
		animated_sprite.frame = skins_animated_sprite_3d.frame;
		animated_sprite.scale.x = skins_animated_sprite_3d.scale.x;
		if animated_sprite.animation != current_animation_name:
			animated_sprite.animation = current_animation_name;
