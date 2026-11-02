shader_type spatial;
render_mode cull_disabled;
// ConceptModel3D: colours an untextured image-to-3D mesh by projecting its
// concept image straight on from the front (model-space x/y -> image u/v).
// Rough by design: the colours land about where the concept painted them.

uniform sampler2D concept : source_color, filter_nearest_mipmap;
uniform vec3 bounds_min = vec3(-1.0);
uniform vec3 bounds_size = vec3(2.0);
uniform vec4 crop = vec4(0.0, 0.0, 1.0, 1.0);  // the object's box inside the image (u, v, w, h)
uniform float roughness = 0.9;
uniform vec3 tint : source_color = vec3(1.0);

varying vec3 local;

void vertex() {
	local = VERTEX;
}

// The concepts sit on a plain light-grey background; edges that hit it would glow grey.
bool is_background(vec3 c) {
	return abs(c.r - c.g) < 0.035 && abs(c.g - c.b) < 0.035 && c.r > 0.55;
}

void fragment() {
	vec2 k = (local.xy - bounds_min.xy) / bounds_size.xy;
	vec2 uv = crop.xy + vec2(k.x, 1.0 - k.y) * crop.zw;
	vec3 c = texture(concept, uv).rgb;
	if (is_background(c)) {
		c = texture(concept, mix(uv, crop.xy + crop.zw * 0.5, 0.3)).rgb;  // a little further in
		if (is_background(c)) {
			c = vec3(0.22, 0.2, 0.18);
		}
	}
	ALBEDO = c * tint;
	ROUGHNESS = roughness;
}
