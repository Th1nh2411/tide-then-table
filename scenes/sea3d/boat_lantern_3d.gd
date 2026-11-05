class_name BoatLantern3D
extends RefCounted
## The boat's lamp seen from outside (third person, debug views): a thin dark
## bamboo pole lashed to the rim with a small tin lantern on top, its glass
## glowing round the boat_lamp SpotLight3D. Parts are direct MeshInstance3D
## children of boat_visual: FirstPersonView3D hides them (the lamp is in
## Rin's hand there). No shadows: the light sits inside the glass.

const POLE := "3b3127"
const TIN := "2b2723"
const GLASS := "f2d98a"
const GLOW := Color("ffc27a")


## Pole from `base_y` up to the lantern centred on `at` (boat_visual space).
static func build(boat_visual: Node3D, at: Vector3, base_y: float) -> void:
	var top := at.y - 0.08
	_part(boat_visual, _cylinder(0.018, 0.022, top - base_y), Vector3(at.x, (top + base_y) * 0.5, at.z), POLE)
	var plate := BoxMesh.new()
	plate.size = Vector3(0.13, 0.02, 0.13)
	_part(boat_visual, plate, at + Vector3(0, -0.075, 0), TIN)
	var glass := _part(boat_visual, _cylinder(0.05, 0.05, 0.13), at, GLASS)
	var lit := glass.material_override.duplicate() as StandardMaterial3D
	lit.emission_enabled = true
	lit.emission = GLOW
	lit.emission_energy_multiplier = 2.0
	glass.material_override = lit
	_part(boat_visual, _cylinder(0.02, 0.075, 0.05), at + Vector3(0, 0.09, 0), TIN)
	var ring := BoxMesh.new()
	ring.size = Vector3(0.012, 0.045, 0.05)
	_part(boat_visual, ring, at + Vector3(0, 0.135, 0), TIN)


static func _cylinder(top: float, bottom: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 8
	mesh.rings = 1
	return mesh


static func _part(parent: Node3D, mesh: Mesh, pos: Vector3, hex: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = SeaWorldBuilder3D.mat(hex)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	node.position = pos
	return node
