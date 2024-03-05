shader_type spatial;

render_mode cull_front, unshaded, depth_draw_never;

uniform float outline_max_distance_render;
global uniform vec4 outline_color;
global uniform float outline_width;

void vertex() {
	vec4 clip_position = 
		PROJECTION_MATRIX *
		(MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	
	vec3 clip_normal =
		mat3(PROJECTION_MATRIX) *
		(mat3(MODELVIEW_MATRIX) * NORMAL);
	clip_position.xy +=
		normalize(clip_normal.xy) /
		VIEWPORT_SIZE *
		clip_position.w *
		outline_width;
	POSITION = clip_position;
}

void fragment() {
	// Get the world position of the fragment
    vec3 fragment_world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
    // Get the world position of the camera
    vec3 camera_world_pos = VIEW_MATRIX[3].xyz;
    // Calculate the distance from the camera to the fragment
    float distance = distance(fragment_world_pos, camera_world_pos);

    // Check if the distance is within the maximum distance
    if (distance <= outline_max_distance_render) {
        // Draw the outline
        ALBEDO = outline_color.rgb;
    } else {
        // Discard the fragment
        discard;
    }
}