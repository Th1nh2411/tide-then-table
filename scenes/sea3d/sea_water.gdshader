shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_back, specular_schlick_ggx;
// Night sea (SeaWater3D): rolling waves, small ripples, moon / lamp glints,
// zone colours blended by depth, foam where anything breaks the surface
// (rocks, pier, shore, hulls) and the boat's own shadow (decals skip
// transparent surfaces). Procedural: no textures needed.

uniform vec3 open_color : source_color = vec3(0.05, 0.09, 0.19);
uniform vec3 reef_color : source_color = vec3(0.06, 0.16, 0.25);
uniform vec3 near_color : source_color = vec3(0.10, 0.25, 0.33);
uniform vec3 fog_color : source_color = vec3(0.13, 0.24, 0.26);
uniform vec3 crest_color : source_color = vec3(0.30, 0.47, 0.55);
uniform vec3 foam_color : source_color = vec3(0.78, 0.92, 0.94);
uniform vec3 sky_color : source_color = vec3(0.16, 0.22, 0.36);
uniform float reef_z = -6.7;
uniform float near_z = 21.7;
uniform vec4 fog_rect = vec4(0.0);  // x, z, width, depth; zero size = no fog
uniform float wave_height = 0.03;
uniform float foam_depth = 0.28;
uniform vec3 boat_pos = vec3(0.0, -100.0, 0.0);
uniform vec2 boat_shadow = vec2(1.45, 1.45);  // half extents, boat local x / z
uniform float boat_yaw = 0.0;
uniform float hull_hole = 0.8;  // no water drawn inside the hull (open thúng)
uniform float alpha = 0.9;
// Lamp highlights: low roughness = sharp glints (open sea); the village sets
// them broad and dim so a lamp beside the pier is no hard white patch.
uniform float gloss = 0.12;
uniform float specular_amount = 0.6;
// Moon glint: sharp + stepped at sea; glint_soft 1 = a smooth dim sheen.
uniform float glint_power = 220.0;
uniform float glint_soft = 0.0;
uniform float glint_strength = 1.0;
uniform vec3 moon_dir = vec3(0.3, 0.75, -0.6);  // towards the moon
uniform vec3 moon_color : source_color = vec3(0.75, 0.82, 0.8);
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;

varying vec3 world_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

// Height and slope (d/dx, d/dz) of three long swells.
vec3 swell(vec2 p, float t) {
	vec3 sum = vec3(0.0);
	vec2 dirs[3] = vec2[](normalize(vec2(1.0, 0.35)), normalize(vec2(-0.45, 1.0)), normalize(vec2(0.7, -0.8)));
	float k[3] = float[](0.55, 0.9, 1.7);
	float speed[3] = float[](1.1, 1.4, 2.1);
	float amp[3] = float[](1.0, 0.55, 0.25);
	for (int i = 0; i < 3; i++) {
		float phase = dot(dirs[i], p) * k[i] + t * speed[i];
		sum.x += sin(phase) * amp[i];
		sum.yz += dirs[i] * cos(phase) * amp[i] * k[i];
	}
	return sum;
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 s = swell(world_pos.xz, TIME);
	VERTEX.y += s.x * wave_height;
	NORMAL = normalize(vec3(-s.y * wave_height, 1.0, -s.z * wave_height));
}

void fragment() {
	vec2 p = world_pos.xz;
	float t = TIME;
	// Zone colour, soft edges (open -> reef -> near shore).
	vec3 col = mix(open_color, reef_color, smoothstep(reef_z - 4.0, reef_z + 4.0, p.y));
	col = mix(col, near_color, smoothstep(near_z - 4.0, near_z + 4.0, p.y));
	if (fog_rect.z > 0.0) {
		vec2 inside = smoothstep(vec2(0.0), vec2(3.0), min(p - fog_rect.xy, fog_rect.xy + fog_rect.zw - p));
		col = mix(col, fog_color, inside.x * inside.y);
	}
	// Small ripples bend the normal; their slope comes from finite differences.
	vec2 a = p * 1.4 + t * vec2(0.25, 0.12);
	vec2 b = p * 3.1 - t * vec2(0.18, 0.33);
	float e = 0.08;
	float r0 = noise(a) + 0.5 * noise(b);
	float rx = noise(a + vec2(e, 0.0)) + 0.5 * noise(b + vec2(e, 0.0));
	float rz = noise(a + vec2(0.0, e)) + 0.5 * noise(b + vec2(0.0, e));
	vec3 ripple = vec3(r0 - rx, 0.0, r0 - rz) / e * 0.06;
	NORMAL = normalize(NORMAL + (VIEW_MATRIX * vec4(ripple, 0.0)).xyz);
	// Stylised crests drifting with the swell (the old wave marks).
	// Thin contour lines of a stretched noise read as wave ridges.
	float crest_n = noise(p * vec2(0.7, 2.2) + t * vec2(0.08, 0.3));
	float crest = smoothstep(0.6, 0.63, crest_n) - smoothstep(0.65, 0.69, crest_n);
	crest *= smoothstep(0.1, 0.9, swell(p, t).x * 0.5 + 0.5);
	col = mix(col, crest_color, clamp(crest, 0.0, 1.0) * 0.45);
	// Foam: thin water between this surface and whatever is behind it.
	float depth = texture(depth_tex, SCREEN_UV).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
#else
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
#endif
	vec4 behind = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	behind.xyz /= behind.w;
	float thickness = VERTEX.z - behind.z;
	float edge = 1.0 - smoothstep(0.0, foam_depth, thickness);
	float foam = step(0.35 + 0.4 * noise(p * 4.0 + t * 0.6), edge);
	// The boat's blob shadow.
	vec2 d = p - boat_pos.xz;
	vec2 off = vec2(d.x * cos(boat_yaw) - d.y * sin(boat_yaw), d.x * sin(boat_yaw) + d.y * cos(boat_yaw)) / boat_shadow;
	if (length(off) < hull_hole) {
		discard;
	}
	float shade = 1.0 - smoothstep(0.4, 1.0, length(off));
	col *= 1.0 - shade * 0.55;
	// Water lapping at the hull: a broken ring just outside the shadow.
	float ring = smoothstep(0.08, 0.0, abs(length(off) - 1.02 - 0.04 * sin(t * 3.0)));
	foam = max(foam, step(0.45, ring * noise(p * 5.0 + t * 1.2)));
	// Moon path: a sharp, stepped glint of the moon in the ripples.
	vec3 world_n = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 world_view = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
	float glint = pow(max(dot(reflect(-world_view, world_n), moon_dir), 0.0), glint_power);
	glint = mix(step(0.25, glint), smoothstep(0.0, 0.8, glint), glint_soft) * glint_strength * (1.0 - foam);
	// Night sky caught at grazing angles.
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	ALBEDO = mix(col, foam_color, foam);
	EMISSION = sky_color * fresnel * 0.35 * (1.0 - foam) + moon_color * glint;
	ROUGHNESS = mix(gloss, 0.9, foam);
	SPECULAR = specular_amount;
	ALPHA = mix(alpha, 1.0, foam);
}
