shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_schlick_ggx;
// GhostLook3D: the drowned / ông Tư. Light parts of the body texture read as
// skin -> pale grey-blue-green; dark parts as cloth -> wet, darker. No glow.
// See-through is a PS1 screen-door dither (no sorting): `opacity` for the
// whole body, `edge_fade` thins the silhouette. Slow vertex wobble = water.

uniform sampler2D body_tex : source_color, filter_nearest_mipmap;
uniform bool use_tex = true;
uniform bool use_vertex_color = false;
uniform vec3 skin : source_color = vec3(0.6, 0.68, 0.66);
uniform vec3 cloth : source_color = vec3(0.17, 0.21, 0.22);
uniform float skin_from = 0.42;
uniform float opacity = 1.0;
uniform float edge_fade = 0.65;
uniform float wobble = 0.012;
uniform float wobble_speed = 1.3;

void vertex() {
	float t = TIME * wobble_speed;
	VERTEX += NORMAL * wobble * sin(t * 2.0 + VERTEX.y * 9.0);
	VERTEX.x += wobble * 0.5 * sin(t + VERTEX.y * 5.0);
}

float bayer4(vec2 p) {
	ivec2 i = ivec2(mod(p, 4.0));
	int m[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(m[i.y * 4 + i.x]) + 0.5) / 16.0;
}

void fragment() {
	vec3 c = vec3(0.7);
	if (use_tex) {
		c = texture(body_tex, UV).rgb;
	}
	if (use_vertex_color) {
		c *= COLOR.rgb;
	}
	float l = pow(max(dot(c, vec3(0.2126, 0.7152, 0.0722)), 0.0), 1.0 / 2.2);
	float k = smoothstep(skin_from - 0.08, skin_from + 0.08, l);
	vec3 wet = cloth * (0.55 + l);
	vec3 pale = skin * (0.7 + 0.35 * l);
	ALBEDO = mix(wet, pale, k);
	ROUGHNESS = mix(0.45, 0.85, k);  // soaked cloth keeps a dull sheen
	SPECULAR = 0.3;
	// Screen-door fade, thinner at the silhouette (the PS1 kind of see-through).
	float rim = 1.0 - abs(dot(normalize(NORMAL), normalize(VIEW)));
	float alpha = opacity * (1.0 - edge_fade * smoothstep(0.4, 0.95, rim));
	vec2 cell = floor(FRAGCOORD.xy);
	if (alpha < bayer4(cell)) {
		discard;
	}
}
