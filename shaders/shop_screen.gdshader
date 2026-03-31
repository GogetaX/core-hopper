shader_type canvas_item;

uniform vec4 base_left  : source_color = vec4(0.22, 0.08, 0.33, 1.0); // purple-left
uniform vec4 base_right : source_color = vec4(0.03, 0.03, 0.12, 1.0); // dark navy-right

uniform vec4 glow_pink  : source_color = vec4(0.95, 0.20, 0.90, 1.0);
uniform vec4 glow_blue  : source_color = vec4(0.22, 0.35, 1.00, 1.0);
uniform vec4 glow_warm  : source_color = vec4(1.00, 0.42, 0.18, 1.0);

uniform float pink_strength = 0.95;
uniform float blue_strength = 0.45;
uniform float warm_strength = 0.18;

uniform vec2 pink_center = vec2(0.22, 0.55);
uniform vec2 blue_center = vec2(0.82, 0.78);
uniform vec2 warm_center = vec2(0.10, 0.25);

uniform vec2 pink_size = vec2(0.65, 0.90);
uniform vec2 blue_size = vec2(0.80, 0.80);
uniform vec2 warm_size = vec2(0.35, 0.35);

uniform float vignette_strength = 1.15;

uniform float border_width = 0.012;
uniform vec4 border_color : source_color = vec4(0.42, 0.18, 0.58, 0.45);

uniform float corner_radius = 0.085;
uniform float edge_softness = 0.004;

uniform float animate_strength = 0.015;
uniform float animate_speed = 0.65;

float rounded_box_sdf(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + r;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

float ellipse_glow(vec2 uv, vec2 center, vec2 size) {
	vec2 p = (uv - center) / size;
	float d = dot(p, p);
	return exp(-d * 3.2);
}

void fragment() {
	vec2 uv = UV;

	// subtle drift so it feels alive
	float t = TIME * animate_speed;
	vec2 pink_offset = vec2(sin(t * 0.7), cos(t * 0.5)) * animate_strength;
	vec2 blue_offset = vec2(cos(t * 0.6), sin(t * 0.8)) * animate_strength * 0.7;

	// rounded card mask
	vec2 p = uv - vec2(0.5);
	float sdf = rounded_box_sdf(p, vec2(0.5 - edge_softness), corner_radius);
	float mask = 1.0 - smoothstep(0.0, edge_softness, sdf);

	// base gradient
	vec3 col = mix(base_left.rgb, base_right.rgb, smoothstep(0.18, 0.92, uv.x));

	// layered glows
	float g_pink = ellipse_glow(uv, pink_center + pink_offset, pink_size) * pink_strength;
	float g_blue = ellipse_glow(uv, blue_center + blue_offset, blue_size) * blue_strength;
	float g_warm = ellipse_glow(uv, warm_center, warm_size) * warm_strength;

	col += glow_pink.rgb * g_pink;
	col += glow_blue.rgb * g_blue;
	col += glow_warm.rgb * g_warm;

	// extra lower-left bloom like the mockup
	float lower_bloom = ellipse_glow(uv, vec2(0.32, 0.18), vec2(0.75, 0.35)) * 0.35;
	col += glow_pink.rgb * lower_bloom;

	// vignette
	float vig = distance(uv, vec2(0.5));
	float vignette = 1.0 - smoothstep(0.22, 0.78, vig) * vignette_strength;
	col *= clamp(vignette, 0.18, 1.0);

	// border
	float inner = 1.0 - smoothstep(border_width, border_width + edge_softness, abs(sdf));
	col = mix(col, border_color.rgb, border_color.a * inner);

	COLOR = vec4(col, mask);
}