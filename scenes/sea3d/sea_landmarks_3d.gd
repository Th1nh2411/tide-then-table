class_name SeaLandmarks3D
extends Node3D
## The night sea's way home, all in the world (no HUD text or markers): both
## lighthouses sweep a beam and flash when it faces Rin, the pier lamps glow
## warm, the lobster raft keeps a small green lamp far out (also a clue), and
## DockBell3D rings at the pier head. Halos are fixed-size and ignore the fog,
## so a lamp still reads as a point of light from across the bay.

const BEAM_LENGTH := 24.0
const BEAM_RADIUS := 1.2
## Seconds per turn: the point's lighthouse, then Đá Canh Đêm.
const TURNS := [11.0, 15.0]
## Halo sizes (fixed-size quads: 0.01 ~ 2.5 px of a 360 px screen).
const HALO_BEACON := 0.03
const HALO_PIER := 0.02
const HALO_RAFT := 0.014
const PIER_HEX := "ffc27a"
const RAFT_HEX := "39ff8a"
const PIER_LAMPS := [Vector3(-3.5, 2.4, 11.0), Vector3(4.5, 2.4, 11.0)]

## [pivot, head halo, turn seconds] per lighthouse.
var beams: Array[Array] = []
var raft_lamp: MeshInstance3D
var bell: DockBell3D
var _time := 0.0


static func build(sea: SeaScene3D) -> SeaLandmarks3D:
	var marks := SeaLandmarks3D.new()
	marks.name = "Landmarks"
	marks.set_meta("style_skip", true)
	sea.add_child(marks)
	var hex := DockOmens3D.BEACON_OMEN if OmenPicker.is_tonight("hai_dang") else DockOmens3D.BEACON_CALM
	var towers: Array[Vector3] = [sea.START + Vector3(-7.8, 0.0, 6.3), sea.LIGHTHOUSE_POS + Vector3(-1.8, 0.0, -0.6)]
	for i in towers.size():
		marks._lighthouse(Vector3(towers[i].x, _top_of(sea, towers[i]), towers[i].z), hex, TURNS[i])
	var pier := Vector3(sea.START.x, 0.0, sea.START.z - 5.0)
	for at: Vector3 in PIER_LAMPS:
		marks._lamp(pier + at, PIER_HEX, 0.09, HALO_PIER, 0.9)
	marks.raft_lamp = marks._lamp(sea.RAFT_POS + Vector3(1.6, 1.7, 0.8), RAFT_HEX, 0.06, HALO_RAFT, 0.35)
	SeaWorldBuilder3D.glow(marks, sea.RAFT_POS + Vector3(1.6, 1.6, 0.8), RAFT_HEX, 0.5, 5.0, false)
	marks.bell = DockBell3D.attach(sea, pier + Vector3(0.0, 2.0, 9.0))
	return marks


## Top of the lighthouse model standing at `foot` (its batch model's bounds).
static func _top_of(sea: Node3D, foot: Vector3) -> float:
	var top := 4.0
	for child in sea.get_children():
		if not String(child.name).begins_with("Batch_lighthouse"):
			continue
		var model := child as Node3D
		if Vector2(model.position.x - foot.x, model.position.z - foot.z).length() > 1.0:
			continue
		for node in model.find_children("*", "MeshInstance3D", true, false):
			var mesh := node as MeshInstance3D
			var box := mesh.global_transform * mesh.get_aabb()
			top = maxf(top, box.end.y - sea.global_position.y)
	return top


func _lighthouse(top: Vector3, hex: String, turn: float) -> void:
	var head := _lamp(top, hex, 0.22, HALO_BEACON, 1.0)
	SeaWorldBuilder3D.glow(self, top, hex, 1.6, 12.0, false)
	var pivot := Node3D.new()
	add_child(pivot)
	pivot.position = top
	pivot.rotation.y = float(beams.size()) * 1.9
	for side in [-1.0, 1.0]:
		var cone := MeshInstance3D.new()
		cone.mesh = _beam_mesh(side)
		cone.material_override = SeaGlowMaterials.beam(hex)
		cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pivot.add_child(cone)
	beams.append([pivot, head, turn])


## A cone along +x (or -x) from the lamp: bright at the lamp, fading to
## nothing at its far rim (vertex alpha), tipped up a little so it passes
## over the thúng instead of through Rin's eyes.
static func _beam_mesh(side: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var far := Vector3(side * BEAM_LENGTH, BEAM_LENGTH * 0.02, 0.0)
	var segments := 10
	for i in segments:
		var a0 := TAU * float(i) / segments
		var a1 := TAU * float(i + 1) / segments
		for corner: Vector3 in [Vector3.ZERO, _rim(far, a0), _rim(far, a1)]:
			st.set_color(Color(1, 1, 1, 1.0 if corner == Vector3.ZERO else 0.0))
			st.add_vertex(corner)
	return st.commit()


static func _rim(far: Vector3, angle: float) -> Vector3:
	return far + Vector3(0.0, cos(angle), sin(angle)) * BEAM_RADIUS


func _lamp(at: Vector3, hex: String, radius: float, halo: float, alpha: float) -> MeshInstance3D:
	var bulb := MeshInstance3D.new()
	var shape := SphereMesh.new()
	shape.radius = radius
	shape.height = radius * 2.0
	shape.radial_segments = 8
	shape.rings = 4
	bulb.mesh = shape
	bulb.material_override = SeaGlowMaterials.bulb(hex)
	add_child(bulb)
	bulb.position = at
	var glow := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(halo, halo)
	glow.mesh = quad
	glow.material_override = SeaGlowMaterials.halo(hex, alpha)
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bulb.add_child(glow)
	return glow


func _process(delta: float) -> void:
	_time += delta
	var camera := get_viewport().get_camera_3d()
	for beam in beams:
		var pivot: Node3D = beam[0]
		var head: MeshInstance3D = beam[1]
		var turn: float = beam[2]
		pivot.rotation.y = wrapf(pivot.rotation.y + delta * TAU / turn, -PI, PI)
		if camera == null:
			continue
		# Flash when one of the two beams points at the viewer.
		var to_eye := camera.global_position - pivot.global_position
		var along := absf(pivot.global_basis.x.dot(Vector3(to_eye.x, 0.0, to_eye.z).normalized()))
		var flash := pow(along, 24.0)
		head.scale = Vector3.ONE * (1.0 + flash * 1.6)
		(head.material_override as StandardMaterial3D).albedo_color.a = 0.75 + flash * 0.25
	if raft_lamp:  # a hung lamp: a slow, uneven breath
		var a := 0.3 + 0.08 * sin(_time * 1.3) + 0.04 * sin(_time * 3.7)
		(raft_lamp.material_override as StandardMaterial3D).albedo_color.a = a
