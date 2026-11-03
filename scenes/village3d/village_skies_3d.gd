class_name VillageSkies3D
extends RefCounted
## The village map's three outdoor looks (VillageLighting3D swaps them):
## grey dawn, the shift's dusk, the moonlit night.

## Painted dusk sky for the shift (used when the file exists, else a gradient sky).
const DUSK_PANORAMA := "res://assets/textures/horror/sky_dusk_pano.png"
const DAWN_PANORAMA := "res://assets/textures/sea3d/sky_dawn_overcast.png"


## Grey dawn after the night: a pale overcast panorama, no sun.
static func morning() -> Environment:
	var env := Environment.new()
	var sky := Sky.new()
	sky.sky_material = SeaBackdrop3D.panorama_material(load(DAWN_PANORAMA) as Texture2D)
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("a9b2b8")
	env.ambient_light_energy = 0.55
	env.fog_enabled = true
	env.fog_sky_affect = 0.3
	env.fog_light_color = Color("98a2aa")
	env.fog_density = 0.025
	return env


## Evening for the shift: the restaurant's light, a dusk sky and a little fog.
static func dusk(street: Environment) -> Environment:
	var env := street.duplicate() as Environment
	var sky := Sky.new()
	if ResourceLoader.exists(DUSK_PANORAMA):
		sky.sky_material = SeaBackdrop3D.panorama_material(load(DUSK_PANORAMA) as Texture2D)
	else:
		var gradient := ProceduralSkyMaterial.new()
		gradient.sky_top_color = Color("2b2c45")
		gradient.sky_horizon_color = Color("a8706a")
		gradient.sky_curve = 0.12
		gradient.ground_horizon_color = Color("5e4c52")
		gradient.ground_bottom_color = Color("1e1e26")
		gradient.sun_angle_max = 8.0
		gradient.sun_curve = 0.3
		sky.sky_material = gradient
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.fog_enabled = true
	env.fog_light_color = Color("6e5f68")
	env.fog_density = 0.016
	env.fog_sky_affect = 0.35
	return env


## Moonlit night: the sea's sky panorama turned to the moon (`sun` aimed there for a moment).
static func night(sun: DirectionalLight3D) -> Environment:
	var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("819796")
	env.ambient_light_energy = 0.55
	env.fog_enabled = true
	env.fog_light_color = Color("172038")
	env.fog_density = 0.02
	var keep := sun.rotation_degrees
	sun.rotation_degrees = Vector3(-48, 152, 0)
	SeaBackdrop3D.apply_sky(env, sun)
	sun.rotation_degrees = keep
	return env
