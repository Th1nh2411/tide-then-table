shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;
// PS1-style surface (PsxLook3D): nearest textures; optional vertex snap to a
// coarse screen grid (the PS1 "wobble", off by default: edges jitter); lighting stays Godot's.

uniform vec4 albedo_color : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_nearest_mipmap, repeat_enable;
uniform bool use_tex = false;
uniform bool use_vertex_color = false;
uniform vec4 uv_scale_offset = vec4(1.0, 1.0, 0.0, 0.0);
uniform vec3 emission : source_color = vec3(0.0);
uniform float roughness = 0.9;
uniform bool snap = false;
uniform vec2 snap_res = vec2(320.0, 180.0);
// World-triplanar source materials (HorrorMaterials.tiled): tile by world metres, not mesh UVs.
uniform bool triplanar = false;
varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	UV = UV * uv_scale_offset.xy + uv_scale_offset.zw;
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	if (snap) {
		vec2 half_res = snap_res * 0.5;
		clip.xy = round(clip.xy / clip.w * half_res) / half_res * clip.w;
	}
	POSITION = clip;
}

void fragment() {
	vec4 c = albedo_color;
	if (use_tex) {
		vec2 uv = UV;
		if (triplanar) {
			vec3 n = abs(world_normal);
			vec3 p = world_pos * uv_scale_offset.x;
			uv = n.y > max(n.x, n.z) ? p.xz : (n.x > n.z ? vec2(p.z, -p.y) : vec2(p.x, -p.y));
		}
		c *= texture(albedo_tex, uv);
	}
	if (use_vertex_color) {
		c *= COLOR;
	}
	ALBEDO = c.rgb;
	ROUGHNESS = roughness;
	EMISSION = emission;
}
