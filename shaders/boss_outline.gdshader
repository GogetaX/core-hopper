shader_type canvas_item;

uniform vec4 boss_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 outline_color : source_color = vec4(1.0, 0.5, 0.0, 1.0);
uniform float outline_size = 2.0;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec2 tex_size = vec2(textureSize(TEXTURE, 0));
	vec2 px = outline_size / tex_size;

	float outline = 0.0;

	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			vec2 offset = vec2(float(x), float(y)) * px;
			outline = max(outline, texture(TEXTURE, UV + offset).a);
		}
	}

	if (base.a == 0.0 && outline > 0.0) {
		COLOR = outline_color;
	} else if (base.a > 0.0) {
		COLOR = vec4(boss_color.rgb, base.a * boss_color.a);
	} else {
		COLOR = vec4(0.0);
	}
}