shader_type spatial;
// Edge fog sheet (WorldEdgeLoop3D): a soft unlit veil with no visible edge from
// any angle. Fades at its sides / top / bottom, when seen edge-on, close to the
// camera, and where it cuts through the ground or a wall (soft intersection).
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec4 fog_color : source_color = vec4(0.09, 0.125, 0.22, 1.0);
uniform float alpha = 0.42;
// Fraction of the width that fades out at each side.
uniform float side_fade = 0.45;
// Seen within this angle of edge-on (dot of normal and view) the sheet is gone.
uniform vec2 facing_fade = vec2(0.12, 0.55);
// Metres from the camera: invisible before x, full from y.
uniform vec2 near_fade = vec2(1.5, 7.0);
// Metres behind the sheet over which it blends into the scene it cuts.
uniform float soft_depth = 2.5;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;

void fragment() {
	float u = abs(UV.x * 2.0 - 1.0);
	float sides = 1.0 - smoothstep(1.0 - side_fade, 1.0, u);
	float v = UV.y;  // 0 top, 1 bottom
	float height = smoothstep(0.0, 0.7, v);
	float facing = smoothstep(facing_fade.x, facing_fade.y, abs(dot(normalize(NORMAL), normalize(VIEW))));
	float near = smoothstep(near_fade.x, near_fade.y, -VERTEX.z);
	float depth = texture(depth_tex, SCREEN_UV).r;
	vec4 behind = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	behind.xyz /= behind.w;
	float soft = clamp((VERTEX.z - behind.z) / soft_depth, 0.0, 1.0);
	ALBEDO = fog_color.rgb;
	ALPHA = alpha * sides * height * facing * near * soft;
}
