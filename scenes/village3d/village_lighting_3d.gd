class_name VillageLighting3D
extends Node
## Time of day and light zones on the village map (VillageScene3D):
## MORNING (grey dawn, Rin wakes) -> SHIFT (the restaurant's own evening look,
## from the moment the shift opens) -> NIGHT (moon sky, lamps lit, after the
## shift and back from the sea). Inside Rin's room the interior environment
## takes over (the bulb does the rest). Phase changes blink through black so
## the sky swap never shows. Lamps and glows are swapped by visibility (the
## PS1 look copies materials once, so emission can't be changed live).

## The environment changed (phase or inside / outside): edge fog re-tints.
signal phase_applied

enum Phase { MORNING, SHIFT, NIGHT }
const STYLE_PHASES: Array[String] = ["morning", "shift", "night"]

## Islands on the horizon per phase: [tint, silhouette 0..1 (1 = flat, no lit windows)].
const ISLAND_LOOK := {
	Phase.MORNING: [Color("7c8790"), 1.0],
	Phase.SHIFT: [Color("4e4656"), 0.8],
	Phase.NIGHT: [Color(0.85, 0.88, 0.95), 0.0],
}

@export var blink_in := 0.35
@export var blink_out := 0.6
## Fog density at the far end of the edge paths (WorldEdgeLoop3D).
@export var haze_density := 0.4

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
var _base_fog: Dictionary = {}  # Environment -> its own fog density
var _islands: Array[ShaderMaterial] = []


## `host`: the restaurant root (its RestaurantEnvironment / StreetKeyLight / CoolStreetFill).
func setup(host: Node3D) -> void:
	_world = host.get_node("RestaurantEnvironment") as WorldEnvironment
	_sun = host.get_node("StreetKeyLight") as DirectionalLight3D
	_fill = host.get_node("CoolStreetFill") as DirectionalLight3D
	_envs[Phase.SHIFT] = VillageSkies3D.dusk(_world.environment)
	_envs[Phase.MORNING] = VillageSkies3D.morning()
	_envs[Phase.NIGHT] = VillageSkies3D.night(_sun)
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


## A small lamp at `at` (parent space), lit from the shift on: a bulb under a
## tin shade (`shade` false: the post brings its own).
func add_lamp(parent: Node3D, at: Vector3, shade: bool = true) -> void:
	if shade:
		RestaurantRoomBuilder3D.box(parent, at + Vector3(0, 0.1, 0), Vector3(0.3, 0.05, 0.3), "3f423e")
		RestaurantRoomBuilder3D.box(parent, at + Vector3(0, 0.15, 0), Vector3(0.12, 0.08, 0.12), "3f423e")
	var off := RestaurantRoomBuilder3D.box(parent, at, Vector3(0.1, 0.12, 0.1), "6b6355")
	var on := RestaurantRoomBuilder3D.box(parent, at, Vector3(0.11, 0.13, 0.11), "f2d98a")
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


## Island strips (SeaBackdrop3D) that follow the time of day.
func add_islands(material: ShaderMaterial) -> void:
	_islands.append(material)
	_tint_islands()


## Edge fog: 0 = the phase's own fog, 1 = a wall (haze_density).
func set_haze(amount: float) -> void:
	var env := _world.environment
	for other: Environment in _base_fog:
		if other != env:
			other.fog_density = _base_fog[other]
	if not _base_fog.has(env):
		_base_fog[env] = env.fog_density
	env.fog_density = lerpf(_base_fog[env], haze_density, clampf(amount, 0.0, 1.0))


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
	phase_applied.emit()


## The current sky's fog colour (WorldEdgeLoop3D's sheets match it).
func fog_color() -> Color:
	return _current().fog_light_color if _world else Color("172038")


func _current() -> Environment:
	return _interiors[phase] if inside else _envs[phase]


func _apply() -> void:
	_world.environment = _current()
	var style_phase: String = STYLE_PHASES[phase]
	StylePass3D.set_phase(style_phase)  # albedo tint (StyleGuide)
	match phase:
		Phase.MORNING:
			_aim(_sun, Vector3(-35, 140, 0), "c8cfd4", 0.45)
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
	_tint_islands()
	phase_applied.emit()


func _tint_islands() -> void:
	var look: Array = ISLAND_LOOK[phase]
	for material in _islands:
		material.set_shader_parameter("tint", look[0])
		material.set_shader_parameter("silhouette", look[1])


static func _aim(light: DirectionalLight3D, degrees: Vector3, hex: String, energy: float) -> void:
	light.rotation_degrees = degrees
	light.light_color = Color(hex)
	light.light_energy = energy
