class_name VillageLighting3D
extends Node
## Time of day and light zones on the village map (VillageScene3D):
## MORNING (grey dawn, Rin wakes) -> SHIFT (the restaurant's own evening look,
## from the moment the shift opens) -> NIGHT (moon sky, lamps lit, after the
## shift and back from the sea). Inside Rin's room the interior environment
## takes over (the bulb does the rest). Phase changes blink through black so
## the sky swap never shows. Lamps and glows are swapped by visibility (the
## PS1 look copies materials once, so emission can't be changed live).

enum Phase { MORNING, SHIFT, NIGHT }

@export var blink_in := 0.35
@export var blink_out := 0.6

var phase := Phase.MORNING
var inside := false
var _world: WorldEnvironment
var _sun: DirectionalLight3D
var _fill: DirectionalLight3D
var _envs: Dictionary = {}  # Phase -> Environment
## Phase -> the same sky seen through the doorway, with the room's dim ambient.
var _interiors: Dictionary = {}
## Node -> phases it shows in.
var _shown_in: Dictionary = {}
var _black := ColorRect.new()


## `host`: the restaurant root (its RestaurantEnvironment / StreetKeyLight / CoolStreetFill).
func setup(host: Node3D) -> void:
	_world = host.get_node("RestaurantEnvironment") as WorldEnvironment
	_sun = host.get_node("StreetKeyLight") as DirectionalLight3D
	_fill = host.get_node("CoolStreetFill") as DirectionalLight3D
	_envs[Phase.SHIFT] = _world.environment
	_envs[Phase.MORNING] = _morning_env()
	_envs[Phase.NIGHT] = _night_env()
	for key: Phase in _envs:
		var room := (_envs[key] as Environment).duplicate() as Environment
		room.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		room.ambient_light_color = Color("5d6a78")
		room.ambient_light_energy = 0.35
		room.ssao_enabled = false
		_interiors[key] = room
	var layer := CanvasLayer.new()
	layer.layer = 25
	add_child(layer)
	_black.color = Color.BLACK
	_black.modulate.a = 0.0
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_black)


## A street lamp bulb at `at` (parent space), lit from the shift on.
func add_lamp(parent: Node3D, at: Vector3) -> void:
	var off := RestaurantRoomBuilder3D.box(parent, at, Vector3(0.22, 0.22, 0.22), "6b6355")
	var on := RestaurantRoomBuilder3D.box(parent, at, Vector3(0.23, 0.23, 0.23), "f2d98a")
	var m := on.material_override as StandardMaterial3D
	m.emission_enabled = true
	m.emission = Color("ffd39b")
	m.emission_energy_multiplier = 1.5
	var light := OmniLight3D.new()
	parent.add_child(light)
	light.position = at
	light.light_color = Color("ffc27a")
	light.light_energy = 1.4
	light.omni_range = 9.0
	light.shadow_enabled = true
	show_in(off, [Phase.MORNING])
	show_in(on, [Phase.SHIFT, Phase.NIGHT])
	show_in(light, [Phase.SHIFT, Phase.NIGHT])


## `node` is visible only in these phases.
func show_in(node: Node3D, phases: Array) -> void:
	_shown_in[node] = phases
	node.visible = phases.has(phase)


## Changes the time of day; `blink` hides the swap behind a short black.
## `phase` is the new one at once; the light follows behind the black.
func set_phase(next: Phase, blink: bool = true) -> void:
	phase = next
	if not blink or not is_inside_tree():
		_apply()
		return
	var tween := create_tween()
	tween.tween_property(_black, "modulate:a", 1.0, blink_in)
	tween.tween_callback(_apply)
	tween.tween_property(_black, "modulate:a", 0.0, blink_out)


## Rin crossed the doorway.
func set_inside(now_inside: bool) -> void:
	if now_inside == inside:
		return
	inside = now_inside
	_world.environment = _current()


func _current() -> Environment:
	return _interiors[phase] if inside else _envs[phase]


func _apply() -> void:
	_world.environment = _current()
	match phase:
		Phase.MORNING:
			_aim(_sun, Vector3(-35, 140, 0), "c8cfd4", 0.6)
			_fill.light_energy = 0.12
		Phase.SHIFT:
			_aim(_sun, Vector3(-52, -30, 0), "ffe1b8", 0.7)
			_fill.light_energy = 0.25
		Phase.NIGHT:
			_aim(_sun, Vector3(-48, 152, 0), "bacac7", 0.45)
			_fill.light_energy = 0.2
	for key: Variant in _shown_in:
		if is_instance_valid(key):
			(key as Node3D).visible = (_shown_in[key] as Array).has(phase)


static func _aim(light: DirectionalLight3D, degrees: Vector3, hex: String, energy: float) -> void:
	light.rotation_degrees = degrees
	light.light_color = Color(hex)
	light.light_energy = energy


## Grey dawn after the night: a pale overcast panorama, no sun.
func _morning_env() -> Environment:
	var env := Environment.new()
	var sky_material := PanoramaSkyMaterial.new()
	sky_material.panorama = load("res://assets/textures/sea3d/sky_dawn_overcast.png") as Texture2D
	var sky := Sky.new()
	sky.sky_material = sky_material
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("a9b2b8")
	env.ambient_light_energy = 0.85
	env.fog_enabled = true
	env.fog_sky_affect = 0.3
	env.fog_light_color = Color("98a2aa")
	env.fog_density = 0.025
	return env


## Moonlit night: the sea's sky panorama turned to the moon light.
func _night_env() -> Environment:
	var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("819796")
	env.ambient_light_energy = 0.55
	env.fog_enabled = true
	env.fog_light_color = Color("172038")
	env.fog_density = 0.02
	var keep := _sun.rotation_degrees
	_sun.rotation_degrees = Vector3(-48, 152, 0)
	SeaBackdrop3D.apply_sky(env, _sun)
	_sun.rotation_degrees = keep
	return env
