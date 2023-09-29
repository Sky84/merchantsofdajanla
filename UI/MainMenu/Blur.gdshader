// Original by ChaffDave : https://godotshaders.com/shader/tilt-shift-shader/

shader_type canvas_item;

uniform float blur: hint_range(0.0,3.0) = 2.0;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment(){
	COLOR = textureLod(screen_texture, SCREEN_UV, blur);

}