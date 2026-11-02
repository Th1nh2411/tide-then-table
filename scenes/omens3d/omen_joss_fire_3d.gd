class_name OmenJossFire3D
extends Node3D
## "vang_ma", a custom (shown on some calm nights, OmenPicker.state): joss
## paper burning in a tin bucket by the curb, embers glowing, smoke rising and
## drifting with the sea wind towards the home end: eerie but right. On its
## night the fire is low and the smoke and burning papers fly the other way,
## against the wind, all along the street to the dock.

const OMEN_ID := "vang_ma"
const WIND_X := -1.0  # same wind as the ribbons in StreetOmens3D
const SMOKE := 10
const PAPERS := 12
const STREET_X := 19.5

@export var smoke_speed: float = 0.5
@export var paper_speed: float = 1.1

var wrong := false
var _smoke: Array[MeshInstance3D] = []
var _papers: Array[MeshInstance3D] = []
var _fire: OmniLight3D
var _time := 0.0


func _ready() -> void:
	wrong = OmenPicker.state(OMEN_ID) == "omen"
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	ConceptModel3D.spawn(self, "joss_paper_bucket", Vector3.ZERO, 0.45)
	OmenProps3D.glow_box(self, Vector3(0, 0.41, 0), Vector3(0.3, 0.02, 0.3), "ff7a2a", 1.5 if wrong else 4.0)
	_fire = OmenProps3D.light(self, Vector3(0, 0.8, 0), "ff9a4a", 0.6 if wrong else 1.6, 3.5)
	for i: int in range(SMOKE):
		var puff := OmenProps3D.box(self, Vector3.ZERO, Vector3(0.18, 0.18, 0.18), "8a8e92")
		var haze := puff.material_override as StandardMaterial3D
		haze.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		haze.albedo_color.a = 0.4
		puff.set_meta("age", float(i) / SMOKE)
		_smoke.append(puff)
	if not wrong:
		return
	for i: int in range(PAPERS):
		var paper := OmenProps3D.glow_box(self, Vector3(rng.randf_range(-STREET_X, STREET_X) - position.x, 0.3,
			rng.randf_range(-2.0, 0.1)), Vector3(0.14, 0.004, 0.1), "e6b84a", 0.8)
		paper.set_meta("phase", rng.randf() * TAU)
		_papers.append(paper)


func _process(delta: float) -> void:
	_time += delta
	var drift := -WIND_X if wrong else WIND_X
	_fire.light_energy = (0.6 if wrong else 1.6) * (0.8 + 0.2 * sin(_time * 13.0) * sin(_time * 7.0))
	for puff in _smoke:
		var age: float = fmod(float(puff.get_meta("age")) + delta * 0.25, 1.0)
		puff.set_meta("age", age)
		puff.position = Vector3(drift * age * 2.5, 0.5 + age * 4.4 * smoke_speed, sin(age * 9.0) * 0.1)
		puff.scale = Vector3.ONE * (0.6 + age * 1.6)
	for paper in _papers:
		var phase: float = paper.get_meta("phase")
		paper.position.x += drift * paper_speed * delta * (0.7 + 0.3 * sin(phase))
		var world_x := paper.position.x + position.x
		if absf(world_x) > STREET_X:
			paper.position.x = -signf(world_x) * STREET_X - position.x
		paper.position.y = 0.25 + 0.55 * absf(sin(_time * 0.9 + phase))
		paper.rotation = Vector3(_time * 2.0 + phase, _time * 1.3, sin(_time * 3.0 + phase))
