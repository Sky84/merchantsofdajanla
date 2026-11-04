shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled, depth_draw_never, depth_test_disabled;

uniform sampler2D frame_atlas : source_color, filter_nearest, repeat_disable;
uniform sampler2D scene_depth : hint_depth_texture, filter_nearest, repeat_disable;
uniform vec4 silhouette_color : source_color = vec4(0.65, 0.8, 0.9, 1.0);
uniform int billboard_mode = 0;
uniform float depth_bias = 0.08;

void vertex() {
	// material_override replaces Godot's built-in billboard shader too.
	if (billboard_mode == 1) {
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
		MODELVIEW_MATRIX *= mat4(
			vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
			vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
			vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
			vec4(0.0, 0.0, 0.0, 1.0));
	} else if (billboard_mode == 2) {
		vec3 up = normalize(MODEL_MATRIX[1].xyz);
		vec3 right = normalize(cross(up, INV_VIEW_MATRIX[2].xyz));
		MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			vec4(right * length(MODEL_MATRIX[0].xyz), 0.0),
			MODEL_MATRIX[1],
			vec4(normalize(cross(right, up)) * length(MODEL_MATRIX[2].xyz), 0.0),
			MODEL_MATRIX[3]);
	}
}

void fragment() {
	if (texture(frame_atlas, UV).a < 0.5) {
		discard;
	}
	float depth = texture(scene_depth, SCREEN_UV).r;
	// Solve projected Z directly. This also avoids Godot 4.3's incorrect
	// INV_PROJECTION_MATRIX for orthographic cameras (engine issue #68878).
	float surface_distance = -(PROJECTION_MATRIX[3][2] - depth * PROJECTION_MATRIX[3][3])
		/ (depth * PROJECTION_MATRIX[2][3] - PROJECTION_MATRIX[2][2]);
	float character_distance = -VERTEX.z;
	// Discard exposed pixels, including the character's own depth prepass.
	if (character_distance <= surface_distance + depth_bias) {
		discard;
	}
	ALBEDO = silhouette_color.rgb;
	// Alpha routes this pass after opaque geometry; opacity 1 avoids stacking
	// several clothing layers into a brighter or darker silhouette.
	ALPHA = silhouette_color.a;
}
