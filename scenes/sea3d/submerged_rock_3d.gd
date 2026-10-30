class_name SubmergedRock3D
extends Node3D
## Đá ngầm: a rock just under the surface with foam breaking over it. The
## collider is always there; the rock and foam fade in only inside the lamp's
## reach (`view_range`, set by the sea scene like BubbleSpot3D), so in the
## dark it is invisible until the boat is close.

const FOAM_COUNT: int = 12
const FADE_SPEED: float = 3.0

var viewer: Node3D
var view_range: float = 8.0
var radius: float = 1.0
## 0 = hidden, 1 = fully seen.
var reveal: float = 0.0
var _rock_mat := StandardMaterial3D.new()
var _foam_mat := StandardMaterial3D.new()
var _foam: Array[MeshInstance3D] = []
var _clock: float = 0.0


func setup(pos: Vector3, radius_: float, viewer_: Node3D) -> void:
	position = pos
	radius = radius_
	viewer = viewer_
	_rock_mat.albedo_color = Color("4a5f63", 0.0)
	_rock_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_rock_mat.roughness = 1.0
	_foam_mat.albedo_color = Color("dbeef0", 0.0)
	_foam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_foam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var top := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.85
	mesh.bottom_radius = radius
	mesh.height = 0.08
	mesh.radial_segments = 7
	top.mesh = mesh
	top.material_override = _rock_mat
	top.position.y = 0.09
	top.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(top)
	# Two low knobs breaking the surface.
	for knob: Vector3 in [Vector3(-0.3, 0.16, 0.15), Vector3(0.25, 0.14, -0.2)]:
		var k := MeshInstance3D.new()
		var km := SphereMesh.new()
		km.radius = radius * 0.32
		km.height = radius * 0.3
		km.radial_segments = 6
		km.rings = 2
		k.mesh = km
		k.material_override = _rock_mat
		k.position = knob * radius
		k.position.y = knob.y
		k.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(k)
	for i in range(FOAM_COUNT):
		var foam := MeshInstance3D.new()
		var bar := BoxMesh.new()
		bar.size = Vector3(0.32, 0.02, 0.06)
		foam.mesh = bar
		foam.material_override = _foam_mat
		foam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(foam)
		_foam.append(foam)
	var body := StaticBody3D.new()
	add_child(body)
	body.position.y = 0.32
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = 0.62
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	update_view(0.0)


func _process(delta: float) -> void:
	_clock += delta
	update_view(delta)


## Separate from _process so tests can step it by hand.
func update_view(delta: float) -> void:
	var seen := is_instance_valid(viewer) and viewer.position.distance_to(position) <= view_range + radius
	reveal = move_toward(reveal, 1.0 if seen else 0.0, delta * FADE_SPEED) if delta > 0.0 else (1.0 if seen else 0.0)
	_rock_mat.albedo_color.a = reveal * 0.95
	_foam_mat.albedo_color.a = reveal * 0.8
	for i in range(_foam.size()):
		var a := TAU * float(i) / float(_foam.size()) + sin(_clock * 0.8 + float(i)) * 0.12
		var r := radius * (1.15 + sin(_clock * 2.2 + float(i) * 1.7) * 0.08)
		_foam[i].position = Vector3(cos(a) * r, 0.12, sin(a) * r)
		_foam[i].rotation.y = -a + PI / 2.0
		_foam[i].visible = reveal > 0.01
