class_name OmenProps3D
extends RefCounted
## Placeholder geometry shared by the omen props (restaurant, street, dock).


static func box(parent: Node3D, pos: Vector3, size: Vector3, hex: String) -> MeshInstance3D:
	var mesh := RestaurantRoomBuilder3D.box(parent, pos, size, hex)
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh


## Self-lit, so it shows in the dark (candles, incense tips, lanterns).
static func glow_box(parent: Node3D, pos: Vector3, size: Vector3, hex: String, energy: float = 2.0) -> MeshInstance3D:
	var mesh := box(parent, pos, size, hex)
	var material := mesh.material_override as StandardMaterial3D
	material.emission_enabled = true
	material.emission = Color(hex)
	material.emission_energy_multiplier = energy
	return mesh


static func sphere(parent: Node3D, pos: Vector3, radius: float, hex: String, energy: float = 0.0) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := SphereMesh.new()
	shape.radius = radius
	shape.height = radius * 2.0
	shape.radial_segments = 10
	shape.rings = 6
	mesh.mesh = shape
	var material := RestaurantRoomBuilder3D.mat(hex)
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = Color(hex)
		material.emission_energy_multiplier = energy
	mesh.material_override = material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh)
	mesh.position = pos
	return mesh


## Flat black, ignores light: a shadow that stays a shadow under any lamp.
static func shadow_box(parent: Node3D, pos: Vector3, size: Vector3) -> MeshInstance3D:
	var mesh := box(parent, pos, size, "050507")
	var material := mesh.material_override as StandardMaterial3D
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mesh


static func light(parent: Node3D, pos: Vector3, hex: String, energy: float, range_: float) -> OmniLight3D:
	var lamp := OmniLight3D.new()
	parent.add_child(lamp)
	lamp.position = pos
	lamp.light_color = Color(hex)
	lamp.light_energy = energy
	lamp.omni_range = range_
	return lamp
