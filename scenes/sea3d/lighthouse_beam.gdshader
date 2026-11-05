shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
// Lighthouse beam (SeaLandmarks3D): a soft sweep, not a solid wedge.
// UV.x runs 0 at the lamp -> 1 at the far end. Fades along its length, towards
// its silhouette (thin, misty edges) and near the camera (never fills the sky
// over Rin's head).

uniform vec3 beam_color : source_color = vec3(1.0, 0.85, 0.6);
uniform float strength = 0.35;
uniform float length_power = 1.8;  // higher = fades sooner from the lamp
uniform float edge_power = 2.5;  // higher = thinner bright core
uniform vec2 near_fade = vec2(4.0, 16.0);  // camera distance (m): hidden -> full

void fragment() {
	float along = pow(clamp(1.0 - UV.x, 0.0, 1.0), length_power);
	float core = pow(abs(dot(normalize(NORMAL), normalize(VIEW))), edge_power);
	float near = smoothstep(near_fade.x, near_fade.y, length(VERTEX));
	ALBEDO = beam_color;
	ALPHA = clamp(strength * along * core * near, 0.0, 1.0);
}
