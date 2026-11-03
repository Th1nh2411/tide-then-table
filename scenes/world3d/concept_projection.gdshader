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
uniform vec3 fallback_color : source_color = vec3(0.22, 0.2, 0.18);
// Optional rod deformation, in the original inferred mesh coordinates.
uniform vec3 bend_axis = vec3(0.0, 1.0, 0.0);
uniform vec3 bend_origin = vec3(0.0);
uniform vec3 bend_direction = vec3(1.0, 0.0, 0.0);
uniform float bend_length = 1.0;
uniform float bend = 0.0;
uniform float glow = 0.0;
uniform vec3 projection_u = vec3(1.0, 0.0, 0.0);
uniform vec3 projection_v = vec3(0.0, 1.0, 0.0);
uniform bool surface_textures = false;
// Buildings need surface materials on every facade: the concept includes
// freestanding furniture that must never become paint on a wall.
uniform bool project_front_detail = true;
uniform sampler2D wall_texture : source_color, filter_nearest_mipmap, repeat_enable;
uniform sampler2D roof_texture : source_color, filter_nearest_mipmap, repeat_enable;

varying vec3 local;
varying vec3 world_position;
varying vec3 original_normal;

void vertex() {
	local = VERTEX;
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	original_normal = NORMAL;
	float along = clamp(dot(VERTEX - bend_origin, bend_axis) / bend_length, 0.0, 1.0);
	VERTEX += bend_direction * bend_length * along * along * bend;
}

// The concepts sit on a plain light-grey background; edges that hit it would glow grey.
bool is_background(vec3 c) {
	return abs(c.r - c.g) < 0.035 && abs(c.g - c.b) < 0.035 && c.r > 0.55;
}

void fragment() {
	vec3 normalized = (local - bounds_min) / max(bounds_size, vec3(0.0001));
	vec2 k = vec2(dot(normalized, projection_u), dot(normalized, projection_v));
	vec2 uv = crop.xy + vec2(k.x, 1.0 - k.y) * crop.zw;
	vec4 source = texture(concept, uv);
	vec3 c = source.rgb;
	if (source.a < 0.5 || is_background(c)) {
		vec4 inner = texture(concept, mix(uv, crop.xy + crop.zw * 0.5, 0.3));
		c = inner.rgb;  // a little further in, without sampling the removed background
		if (inner.a < 0.5 || is_background(c)) {
			c = fallback_color;
		}
	}
	// Front detail comes from the concept; side walls / roof use actual repeating
	// materials instead of stretching a single row of the concept over the mesh.
	if (surface_textures) {
		vec3 n = normalize(original_normal);
		vec3 front = normalize(cross(projection_u, projection_v));
		if (n.y > 0.55 && normalized.y > 0.55) {
			c = texture(roof_texture, world_position.xz / 1.4).rgb;
		} else if (!project_front_detail || abs(dot(n, front)) < 0.6) {
			vec2 wall_uv = abs(n.x) > abs(n.z) ? world_position.zy : world_position.xy;
			c = texture(wall_texture, wall_uv / 1.6).rgb;
		}
	}
	ALBEDO = c * tint;
	ROUGHNESS = roughness;
	EMISSION = c * glow;
}
