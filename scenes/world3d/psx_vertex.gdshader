shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;
// PS1-style surface (PsxLook3D): vertices snap to a coarse screen grid
// (the "wobble"), textures sample nearest; lighting stays Godot's.

uniform vec4 albedo_color : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_nearest, repeat_enable;
uniform bool use_tex = false;
uniform bool use_vertex_color = false;
uniform vec4 uv_scale_offset = vec4(1.0, 1.0, 0.0, 0.0);
uniform vec3 emission : source_color = vec3(0.0);
uniform float roughness = 0.9;
uniform vec2 snap_res = vec2(320.0, 180.0);

void vertex() {
	UV = UV * uv_scale_offset.xy + uv_scale_offset.zw;
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	vec2 half_res = snap_res * 0.5;
	clip.xy = round(clip.xy / clip.w * half_res) / half_res * clip.w;
	POSITION = clip;
}

void fragment() {
	vec4 c = albedo_color;
	if (use_tex) {
		c *= texture(albedo_tex, UV);
	}
	if (use_vertex_color) {
		c *= COLOR;
	}
	ALBEDO = c.rgb;
	ROUGHNESS = roughness;
	EMISSION = emission;
}
