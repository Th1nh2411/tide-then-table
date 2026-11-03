// Shared body of psx_vertex(_2s).gdshader. PS1 surface (PsxLook3D): nearest
// textures, optional vertex snap; lighting stays Godot's. With `style_on`
// (StylePass3D, numbers in StyleGuide) the albedo is graded to the village
// look: desaturated, capped saturation / value, palette pull, phase tint,
// grime blotches + speckle, darker base, texels blocked to one density.

uniform vec4 albedo_color : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_nearest_mipmap, repeat_enable;
uniform bool use_tex = false;
uniform bool use_vertex_color = false;
uniform vec4 uv_scale_offset = vec4(1.0, 1.0, 0.0, 0.0);
uniform bool triplanar = false;
uniform bool triplanar_world = true;
uniform vec3 emission : source_color = vec3(0.0);
uniform float roughness = 0.9;
uniform float metallic = 0.0;
uniform bool snap = false;
uniform vec2 snap_res = vec2(320.0, 180.0);

uniform bool style_on = false;
uniform float saturation = 1.0;
uniform float max_saturation = 1.0;
uniform float max_value = 1.0;
uniform float black_lift = 0.0;
uniform vec3 tint = vec3(1.0);  // sRGB multiplier
uniform float palette_pull = 0.0;
uniform vec3 palette[48];  // sRGB
uniform int palette_size = 0;
uniform float grime_scale = 0.7;
uniform float grime_amount = 0.0;
uniform float speckle_cells = 24.0;
uniform float speckle_amount = 0.0;
uniform float base_height = 0.4;
uniform float base_dark = 0.0;
uniform float texel_step = 1.0;

varying vec3 world_pos;
varying vec3 world_normal;
varying vec3 model_pos;

void vertex() {
	UV = UV * uv_scale_offset.xy + uv_scale_offset.zw;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	model_pos = VERTEX * vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	if (snap) {
		vec2 half_res = snap_res * 0.5;
		clip.xy = round(clip.xy / clip.w * half_res) / half_res * clip.w;
	}
	POSITION = clip;
}

float hash3(vec3 p) {
	return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
}

float value_noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(mix(hash3(i), hash3(i + vec3(1, 0, 0)), f.x), mix(hash3(i + vec3(0, 1, 0)), hash3(i + vec3(1, 1, 0)), f.x), f.y);
	float b = mix(mix(hash3(i + vec3(0, 0, 1)), hash3(i + vec3(1, 0, 1)), f.x), mix(hash3(i + vec3(0, 1, 1)), hash3(i + vec3(1, 1, 1)), f.x), f.y);
	return mix(a, b, f.z);
}

vec2 blocked(vec2 uv) {
	if (texel_step <= 1.0) {
		return uv;
	}
	vec2 size = vec2(textureSize(albedo_tex, 0)) / texel_step;
	return (floor(uv * size) + 0.5) / size;
}

vec4 sample_albedo(vec2 uv) {
	if (!triplanar) {
		return texture(albedo_tex, blocked(uv));
	}
	vec3 p = (triplanar_world ? world_pos : model_pos) * vec3(uv_scale_offset.x, uv_scale_offset.y, uv_scale_offset.x);
	vec3 n = abs(world_normal);
	n /= max(n.x + n.y + n.z, 0.0001);
	return texture(albedo_tex, blocked(p.zy)) * n.x + texture(albedo_tex, blocked(p.xz)) * n.y + texture(albedo_tex, blocked(p.xy)) * n.z;
}

// Graded in sRGB (the guide's numbers are what a screenshot shows).
vec3 grade(vec3 linear_c) {
	vec3 c = pow(max(linear_c, vec3(0.0)), vec3(1.0 / 2.2));
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, saturation);
	float hi = max(c.r, max(c.g, c.b));
	float lo = min(c.r, min(c.g, c.b));
	float s = (hi - lo) / max(hi, 0.0001);
	if (s > max_saturation) {
		c = hi - (hi - c) * (max_saturation / s);
	}
	if (palette_pull > 0.0 && palette_size > 0) {
		vec3 best = c;
		float best_d = 1e9;
		for (int i = 0; i < palette_size; i++) {
			vec3 d = palette[i] - c;
			float dd = dot(d, d);
			if (dd < best_d) {
				best_d = dd;
				best = palette[i];
			}
		}
		c = mix(c, best, palette_pull);
	}
	c *= tint;
	hi = max(c.r, max(c.g, c.b));
	if (hi > max_value) {
		c *= max_value / hi;
	}
	c = c * (1.0 - black_lift) + vec3(black_lift);
	return pow(c, vec3(2.2));
}

float grime(vec3 at, vec3 n) {
	// Two octaves, the fine one stretched downwards like old water stains.
	float blot = value_noise(at / max(grime_scale, 0.01)) * 0.6 + value_noise(at * vec3(1.0, 0.35, 1.0) / max(grime_scale * 0.3, 0.01)) * 0.4;
	float speck = hash3(floor(at * speckle_cells));
	float k = 1.0 - grime_amount * smoothstep(0.4, 0.8, blot) - speckle_amount * step(0.82, speck);
	float h = world_pos.y;
	float side = 1.0 - clamp(n.y, 0.0, 1.0);
	k *= 1.0 - base_dark * side * (1.0 - smoothstep(0.0, base_height, h));
	return k;
}

void fragment() {
	vec4 c = albedo_color;
	if (use_tex) {
		c *= sample_albedo(UV);
	}
	if (use_vertex_color) {
		c *= COLOR;
	}
	vec3 rgb = c.rgb;
	if (style_on) {
		rgb = grade(rgb) * grime(triplanar ? world_pos : model_pos, world_normal);
	}
	ALBEDO = rgb;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	EMISSION = emission;
}
