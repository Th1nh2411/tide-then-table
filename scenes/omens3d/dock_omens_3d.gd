class_name DockOmens3D
extends Node3D
## The dock's omen props on the waterfront (WaterfrontScene3D), seen before
## the night's choice, each in its normal or wrong state (OmenPicker.state):
## - "hoa_dang" (a custom, some nights): paper lanterns float out to sea;
##   on its night they drift back in and bunch up against the pier.
## - "hai_dang": the lighthouse beacons (by the pier and far out on Đá Canh
##   Đêm) burn warm yellow; on its night they burn green.
## - "bong_cau_tau": a lamp hangs lit on the post at the pier head; on its
##   night the lamp is out and a dark figure stands by the post.

const LANTERNS := 5
const LANTERN_SPEED := 0.22
const BEACON_CALM := "ffe2a0"
const BEACON_OMEN := "39ff8a"

## Set by build(): the pier-head post, the beacons' tops, and where the lanterns float.
var pier_post: Vector3
var beacon_tops: Array[Vector3] = []
var water_origin: Vector3
var _lanterns: Array[Node3D] = []
var _drift := Vector3(0, 0, -LANTERN_SPEED)
## Lanterns drifting in stop here (just off the pier head).
var _shore_z := 0.0
var _beacons: Array[MeshInstance3D] = []
var _time := 0.0


static func build(owner: Node3D, post: Vector3, beacons: Array[Vector3], water: Vector3) -> DockOmens3D:
	var omens := DockOmens3D.new()
	omens.name = "DockOmens"
	omens.pier_post = post
	omens.beacon_tops = beacons
	omens.water_origin = water
	owner.add_child(omens)
	return omens


func _ready() -> void:
	var start := water_origin
	_shore_z = start.z + 2.4
	var rng := RandomNumberGenerator.new()
	rng.seed = 15
	var lanterns := OmenPicker.state("hoa_dang")
	var inward := lanterns == "omen"
	if inward:
		_drift = Vector3(0, 0, LANTERN_SPEED)
	for i: int in range(LANTERNS if lanterns != "" else 0):
		var lantern := Node3D.new()
		add_child(lantern)
		var far := rng.randf_range(6.0, 16.0) if inward else rng.randf_range(3.0, 11.0)
		lantern.position = start + Vector3(rng.randf_range(-7.0, 7.0), 0.1, -far)
		ConceptModel3D.spawn(lantern, "hoa_dang_lantern", Vector3(0, -0.02, 0), 0.16)
		OmenProps3D.glow_box(lantern, Vector3(0, 0.07, 0), Vector3(0.05, 0.07, 0.05), "ffcf6a", 3.0)
		OmenProps3D.light(lantern, Vector3(0, 0.3, 0), "ffb347", 0.5, 2.5)
		lantern.set_meta("phase", rng.randf() * TAU)
		_lanterns.append(lantern)
	var beacon_hex := BEACON_OMEN if OmenPicker.is_tonight("hai_dang") else BEACON_CALM
	for at: Vector3 in beacon_tops:
		_beacons.append(OmenProps3D.sphere(self, at, 0.45, beacon_hex, 6.0))
		OmenProps3D.light(self, at, beacon_hex, 2.0, 9.0)
	_build_pier_head(pier_post, OmenPicker.is_tonight("bong_cau_tau"))


func _build_pier_head(post: Vector3, figure: bool) -> void:
	ConceptModel3D.spawn(self, "pier_lamp_post", post, 1.5)
	if not figure:
		OmenProps3D.glow_box(self, post + Vector3(0, 0.8, 0.14), Vector3(0.14, 0.18, 0.14), "ffcf6a", 3.0)
		OmenProps3D.light(self, post + Vector3(0, 0.9, 0.3), "ffb347", 1.0, 4.0)
		return
	OmenProps3D.box(self, post + Vector3(0, 0.8, 0.14), Vector3(0.14, 0.18, 0.14), "3a3226")
	ConceptModel3D.spawn(self, "drowned_figure", post + Vector3(-0.8, 0, 0.1), 1.72, PI)


func _process(delta: float) -> void:
	_time += delta
	for lantern in _lanterns:
		var phase: float = lantern.get_meta("phase")
		lantern.position += _drift * delta
		if lantern.position.z > _shore_z:
			lantern.position.z = _shore_z
		lantern.position.y = 0.1 + sin(_time * 1.4 + phase) * 0.04
		lantern.rotation.y += delta * 0.2
	var pulse := 4.0 + 3.0 * absf(sin(_time * 1.2))
	for beacon in _beacons:
		(beacon.material_override as StandardMaterial3D).emission_energy_multiplier = pulse
