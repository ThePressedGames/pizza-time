shader_type spatial;

uniform vec3 water_color : source_color;
uniform float uv_scale : hint_range(0.0, 10.0, 0.1) = 1.0;
uniform float time_scale : hint_range(0.0, 10.0, 0.1) = 1.0;
uniform float _alpha : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform sampler2D water_normal_noise;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable;

void fragment() {

	vec2 _uv = UV * uv_scale;
	_uv.x += sin(TIME * time_scale + (_uv.x + _uv.y) * 25.0) * 0.01;
	_uv.y += cos(TIME * time_scale + (_uv.x - _uv.y) * 25.0) * 0.01;
	vec2 _suv = SCREEN_UV;
	_suv.x += sin(TIME * time_scale + (_suv.x + _suv.y) * 25.0) * 0.01;
	_suv.y += cos(TIME * time_scale + (_suv.x - _suv.y) * 25.0) * 0.01;

	ALBEDO = texture(screen_texture, _suv).rgb;
	NORMAL_MAP = texture(water_normal_noise, _uv).rgb;
	NORMAL_MAP *= 0.5;
	ROUGHNESS = .2;
	
	ALPHA = _alpha;
}