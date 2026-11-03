shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;
// Blocky pixel noise over a face (glitch_face), on a quad that always faces
// the camera: steps at `rate` per second, rows tear sideways, dark and pale
// blocks with holes so bits of the face still show, ragged round edge.

uniform float blocks = 9.0;
uniform float rate = 12.0;
uniform float strength : hint_range(0.0, 1.0) = 0.95;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	float frame = floor(TIME * rate);
	vec2 cell = floor(UV * blocks);
	// A row tears sideways now and then.
	float tear = step(0.78, hash(vec2(cell.y, frame * 1.7))) * floor(hash(vec2(frame, cell.y)) * 3.0 - 1.0);
	cell.x += tear;
	float n = hash(cell + frame * 0.37);
	float shade = n > 0.6 ? 0.75 + 0.25 * hash(cell * 2.1) : 0.03 + 0.1 * n;
	ALBEDO = vec3(shade * 0.9, shade, shade * 0.93);
	vec2 centre = (cell + 0.5) / blocks - 0.5;
	float edge = length(centre * vec2(1.15, 0.95)) * 2.0 + hash(cell + frame) * 0.35;
	ALPHA = strength * step(0.22, n) * step(edge, 1.0);
}
