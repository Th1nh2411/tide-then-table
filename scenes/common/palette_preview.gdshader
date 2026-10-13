shader_type canvas_item;
// Snaps every pixel on screen to the nearest colour of the game palette
// (PalettePreview, F7 in debug builds): a preview of the art direction.

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform vec3 palette[64];
uniform int count = 0;

void fragment() {
	vec3 c = texture(screen_texture, SCREEN_UV).rgb;
	vec3 pick = c;
	float best = 1e9;
	for (int i = 0; i < 64; i++) {
		if (i >= count) {
			break;
		}
		vec3 p = palette[i];
		vec3 d = c - p;
		float rm = (c.r + p.r) * 0.5;  // "redmean" perceptual distance
		float dist = (2.0 + rm) * d.r * d.r + 4.0 * d.g * d.g + (3.0 - rm) * d.b * d.b;
		if (dist < best) {
			best = dist;
			pick = p;
		}
	}
	COLOR = vec4(pick, 1.0);
}
