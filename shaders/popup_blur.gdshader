shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float blur_lod : hint_range(0.0, 5.0) = 2.2;
uniform vec4 tint : source_color = vec4(0.08, 0.11, 0.20, 0.35);
uniform float saturation : hint_range(0.0, 1.5) = 0.95;
uniform float brightness : hint_range(0.01, 1.5) = 1.0;

void fragment() {
	vec4 orig_color = COLOR;
	vec4 src = textureLod(screen_texture, SCREEN_UV, blur_lod);

	float luma = dot(src.rgb, vec3(0.299, 0.587, 0.114));
	vec3 color = mix(vec3(luma), src.rgb, saturation) * brightness;

	color = mix(color, tint.rgb, tint.a);

	COLOR = vec4(color, orig_color.a);
}