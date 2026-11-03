class_name SeaBackdrop3D
extends RefCounted
## The 3D sea's backdrop: the night sky panorama (moon turned to match the
## moon light, so water glints line up) and island silhouettes on the horizon.

const SKY := preload("res://assets/textures/sea3d/night_sky_panorama_v1.png")
const ISLANDS := preload("res://assets/textures/sea3d/distant_islands_night_v1.png")
## Where the moon sits in the panorama (u, 0..1 across the image).
const MOON_U := 0.675
## Island strips: centre, yaw, width. Height follows the 8:1 texture.
const STRIPS := [
	[Vector3(0, 0, -95), 0.0, 262.0],
	[Vector3(-125, 0, -20), PI * 0.5, 150.0],
	[Vector3(125, 0, -20), -PI * 0.5, 150.0],
]
## Island baseline in the texture, from the top (0..1).
const BASELINE_V := 0.867
## Islands: the painted strip, or (silhouette 1) one flat hazy colour, so
## daylight hides the lit windows (VillageLighting3D sets it per phase).
const ISLAND_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
uniform sampler2D strip : source_color, filter_nearest;
uniform vec4 tint : source_color = vec4(0.85, 0.88, 0.95, 1.0);
uniform float silhouette = 0.0;
void fragment() {
	vec4 c = texture(strip, UV);
	ALBEDO = mix(c.rgb * tint.rgb, tint.rgb, silhouette);
	ALPHA = c.a;
}
"""

## A painted panorama as the sky. The paintings' left and right edges don't
## quite meet (a thin line where they wrap): a narrow band around the seam
## cross-fades with its mirror, so there is no line.
const PANORAMA_SHADER := """
shader_type sky;
uniform sampler2D panorama : source_color, filter_linear, repeat_enable;
uniform float energy = 1.0;
uniform float seam_band = 0.015;
void sky() {
	vec2 uv = vec2(fract(SKY_COORDS.x), SKY_COORDS.y);
	vec3 own = textureLod(panorama, uv, 0.0).rgb;
	float s = uv.x < 0.5 ? uv.x : uv.x - 1.0;
	if (abs(s) < seam_band) {
		vec3 mirror = textureLod(panorama, vec2(fract(-s), uv.y), 0.0).rgb;
		own = mix(mirror, own, 0.5 + 0.5 * abs(s) / seam_band);
	}
	COLOR = own * energy;
}
"""


## Sky material showing `texture` as a seamless panorama.
static func panorama_material(texture: Texture2D) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = PANORAMA_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("panorama", texture)
	return material


## Sky for `env`; `moon` is the scene's moon light (its +Z points at the moon).
## `panorama` / `moon_u`: another painted sky and where its moon sits (đêm âm).
static func apply_sky(env: Environment, moon: DirectionalLight3D, panorama: Texture2D = SKY, moon_u: float = MOON_U) -> void:
	var sky := Sky.new()
	sky.sky_material = panorama_material(panorama)
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	# Panorama u = atan(x, -z) / TAU; turn the sky so the painted moon is where the light comes from.
	var to_moon := moon.global_basis.z
	var light_u := fposmod(atan2(to_moon.x, -to_moon.z) / TAU, 1.0)
	env.sky_rotation = Vector3(0, (moon_u - light_u) * TAU, 0)
	env.fog_sky_affect = 0.25


## Island strips around `parent`: [centre, yaw, width] each (STRIPS by default).
## Returns their material (tint / silhouette uniforms).
static func build_islands(parent: Node3D, strips: Array = STRIPS) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = ISLAND_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("strip", ISLANDS)
	for strip: Array in strips:
		var width: float = strip[2]
		var height := width / 8.0
		var quad := QuadMesh.new()
		quad.size = Vector2(width, height)
		var node := MeshInstance3D.new()
		node.name = "DistantIslands"
		node.mesh = quad
		node.material_override = material
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(node)
		var centre: Vector3 = strip[0]
		node.position = centre + Vector3(0, SeaWater3D.WATER_Y + height * (BASELINE_V - 0.5), 0)
		node.rotation.y = strip[1]
	return material
