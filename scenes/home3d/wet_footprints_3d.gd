class_name WetFootprints3D
extends Node3D
## Wet bare footprints on the bedroom floor, from the door to the bed: the
## drowned visited in the night (a calm night gone wrong). Flat dark glossy
## shapes, no words. They stay for that morning (built with the room).

const NODE_NAME := "WetFootprints"
const STEP := 0.34
const SIDE := 0.09
const FLOOR_Y := 0.006

@export var color := Color(0.07, 0.09, 0.1, 0.82)


static func build(room: Node3D, from: Vector3, to: Vector3) -> WetFootprints3D:
	var prints := WetFootprints3D.new()
	prints.name = NODE_NAME
	room.add_child(prints)
	prints.lay(from, to)
	return prints


## Lays prints along from -> to (heels towards `from`), starting just inside.
func lay(from: Vector3, to: Vector3) -> void:
	var flat := Vector3(to.x - from.x, 0, to.z - from.z)
	var dir := flat.normalized()
	var side := dir.cross(Vector3.UP)
	var yaw := atan2(dir.x, dir.z)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.05
	mat.metallic_specular = 1.0
	var count := int(flat.length() / STEP)
	for i in range(1, count + 1):
		var left := i % 2 == 0
		var at := from + dir * (i * STEP) + side * (SIDE if left else -SIDE)
		at.y = FLOOR_Y
		_foot(at, yaw + (0.12 if left else -0.12), mat)


func _foot(at: Vector3, yaw: float, mat: Material) -> void:
	var foot := Node3D.new()
	add_child(foot)
	foot.position = at
	foot.rotation.y = yaw
	# Ball of the foot, heel, and a smear of toes.
	for part: Array in [[Vector3(0, 0, 0.04), Vector3(0.085, 0.003, 0.12)],
			[Vector3(0, 0, -0.08), Vector3(0.065, 0.003, 0.08)],
			[Vector3(0.005, 0, 0.13), Vector3(0.075, 0.003, 0.03)]]:
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = part[1]
		mesh.mesh = box
		mesh.material_override = mat
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh.position = part[0]
		foot.add_child(mesh)
