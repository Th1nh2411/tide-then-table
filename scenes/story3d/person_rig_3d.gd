class_name PersonRig3D
extends Node3D
## Blocky character rig shared by gameplay and cutscenes: body, head, hat,
## swinging legs/arms, optional carried plate. Cat is a separate small model.

const SKIN := "ad7757"
const DARK := "202e37"
## kind -> {shirt, hat, glasses, apron}. Guests pass their own shirt colour.
const LOOKS := {
	"rin": {"shirt": "e9dfc5", "hat": DARK, "glasses": true},
	"bao": {"shirt": "c97649", "hat": "394a50", "apron": true},
	"vy": {"shirt": "d9648a", "hat": "394a50"},
	"co_nam": {"shirt": "468232", "hat": "394a50", "bun": true},
	"guest": {"shirt": "7a4841", "hat": "394a50"},
}

var kind: String = ""
var legs: Array[Node3D] = []
var arms: Array[Node3D] = []
var plate: Node3D
var carrying := false


## Builds a rig of `kind` under `parent`. `shirt` overrides the look's shirt hex.
static func build(parent: Node3D, kind_: String, shirt: String = "") -> PersonRig3D:
	var rig := PersonRig3D.new()
	rig.kind = kind_
	parent.add_child(rig)
	if kind_ == "cat":
		rig._build_cat()
		return rig
	var look: Dictionary = LOOKS.get(kind_, LOOKS["guest"])
	rig._build_person(look, shirt if shirt != "" else str(look["shirt"]))
	if kind_ != "guest":
		rig.add_to_group("person_" + kind_)
	return rig


## Walk cycle: `speed` 0..1 scales the swing, `clock` is the step time.
func set_walking(speed: float, clock: float) -> void:
	if kind == "cat":
		return
	var beat := floorf(clock * 8.0) / 8.0
	position.y = absf(sin(beat * 11.0)) * 0.04 * speed
	for i in range(legs.size()):
		var side := -1.0 if i == 0 else 1.0
		legs[i].rotation.x = side * sin(beat * 11.0) * 0.4 * speed
		arms[i].rotation.x = -side * sin(beat * 11.0) * 0.33 * speed
	if carrying:
		for arm in arms:
			arm.rotation.x = -0.8


func set_carrying(on: bool) -> void:
	carrying = on
	if plate:
		plate.visible = on
	if not on:
		for arm in arms:
			arm.rotation.x = 0.0


## Arms up for an emote; pass false to lower them.
func set_raised(on: bool) -> void:
	if not carrying:
		for arm in arms:
			arm.rotation.x = -2.4 if on else 0.0


func _box(parent: Node3D, pos: Vector3, size: Vector3, hex: String) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	m.roughness = 0.85
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mesh.material_override = m
	parent.add_child(mesh)
	mesh.position = pos
	return mesh


func _build_person(look: Dictionary, shirt: String) -> void:
	_box(self, Vector3(0, 1.05, 0), Vector3(0.46, 0.65, 0.33), shirt)
	_box(self, Vector3(0, 1.72, 0), Vector3(0.39, 0.42, 0.37), SKIN)
	_box(self, Vector3(0, 1.97, 0), Vector3(0.48, 0.14, 0.44), str(look["hat"]))
	for side in [-1.0, 1.0]:
		var leg := Node3D.new()
		add_child(leg)
		leg.position = Vector3(side * 0.13, 0.66, 0)
		_box(leg, Vector3(0, -0.27, 0), Vector3(0.15, 0.55, 0.18), SKIN)
		var arm := Node3D.new()
		add_child(arm)
		arm.position = Vector3(side * 0.31, 1.35, 0)
		_box(arm, Vector3(0, -0.3, 0), Vector3(0.12, 0.61, 0.14), SKIN)
		legs.append(leg)
		arms.append(arm)
	if look.get("glasses", false):
		for x in [-0.11, 0.11]:
			_box(self, Vector3(x, 1.76, 0.19), Vector3(0.17, 0.11, 0.035), DARK)
	if look.get("apron", false):
		_box(self, Vector3(0, 0.98, 0.18), Vector3(0.34, 0.6, 0.04), "e9dfc5")
	if look.get("bun", false):
		_box(self, Vector3(0, 1.94, -0.18), Vector3(0.30, 0.17, 0.24), DARK)
	plate = Node3D.new()
	add_child(plate)
	plate.position = Vector3(0, 1.0, 0.47)
	plate.visible = false
	_box(plate, Vector3.ZERO, Vector3(0.36, 0.035, 0.3), "e8d9b7")
	for i in range(3):
		_box(plate, Vector3(-0.1 + i * 0.1, 0.045, 0), Vector3(0.075, 0.05, 0.18), "c97649")


func _build_cat() -> void:
	_box(self, Vector3(0, 0.22, 0), Vector3(0.72, 0.42, 0.48), "de9e41")
	_box(self, Vector3(-0.32, 0.34, 0.16), Vector3(0.38, 0.36, 0.36), "e8c170")
	for x in [-0.44, -0.19]:
		_box(self, Vector3(x, 0.58, 0.16), Vector3(0.12, 0.22, 0.12), "de9e41")
	_box(self, Vector3(0.48, 0.41, -0.12), Vector3(0.10, 0.57, 0.12), "de9e41")
	add_to_group("person_cat")
