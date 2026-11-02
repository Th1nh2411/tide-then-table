class_name FishBasket3D
extends Node3D
## The giỏ cá in the thúng: Rin drops each landed fish in with E while
## looking at it (Fishing3D). Shows the fish stacked inside and a small
## count. What it holds on docking is the night's catch (LoopCalendar).

## Where it sits in the boat (BoatVisual space): low, left of Rin.
const IN_BOAT := Vector3(-0.15, 0.2, -0.2)
const RADIUS := 0.27
const HEIGHT := 0.3
const WICKER := "8a6a3e"

var fish: Array[FishData] = []
var sizes: Array[float] = []
var _stack := Node3D.new()
var _count := Label3D.new()


func _ready() -> void:
	var body := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = RADIUS
	mesh.bottom_radius = RADIUS * 0.8
	mesh.height = HEIGHT
	mesh.radial_segments = 10
	mesh.rings = 1
	body.mesh = mesh
	body.material_override = _mat(WICKER)
	body.position.y = HEIGHT * 0.5
	add_child(body)
	var rim := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = RADIUS - 0.03
	torus.outer_radius = RADIUS + 0.02
	torus.rings = 12
	torus.ring_segments = 4
	rim.mesh = torus
	rim.material_override = _mat("5e4426")
	rim.position.y = HEIGHT
	add_child(rim)
	add_child(_stack)
	_stack.position.y = HEIGHT + 0.01
	_count.font_size = 40
	_count.pixel_size = 0.004
	_count.outline_size = 10
	_count.modulate = Color("efe6d2")
	_count.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_count.position = Vector3(0, HEIGHT + 0.22, 0)
	add_child(_count)
	_refresh()


func count() -> int:
	return fish.size()


func add(caught: FishData, size: float) -> void:
	fish.append(caught)
	sizes.append(size)
	_refresh()


## Top of the basket in world space (Fishing3D's look check).
func mouth() -> Vector3:
	return global_position + global_basis.y * HEIGHT


func _refresh() -> void:
	for child in _stack.get_children():
		child.queue_free()
	for i in range(fish.size()):
		var model := fish_mesh(fish[i], sizes[i] * 0.55)
		_stack.add_child(model)
		var a := float(i) * 2.4
		model.position = Vector3(cos(a) * 0.08, float(i / 3) * 0.05, sin(a) * 0.08)
		model.rotation = Vector3(0, a + PI * 0.5, 0)
	_count.text = str(fish.size()) if not fish.is_empty() else ""


## Placeholder fish: an elongated body in the species colour, a tail and an
## eye, about 0.32 m long at size 1 (scaled by `size`).
static func fish_mesh(caught: FishData, size: float) -> Node3D:
	var root := Node3D.new()
	var color := caught.color if caught else Color("9fb4b8")
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.05
	capsule.height = 0.3
	capsule.radial_segments = 8
	capsule.rings = 2
	body.mesh = capsule
	body.material_override = _mat_color(color)
	body.rotation.z = PI * 0.5
	body.scale = Vector3(1.0, 1.0, 0.7)
	root.add_child(body)
	var tail := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(0.1, 0.09, 0.02)
	tail.mesh = prism
	tail.material_override = _mat_color(color.darkened(0.25))
	tail.position = Vector3(0.18, 0, 0)
	tail.rotation.z = PI * 0.5
	root.add_child(tail)
	var eye := MeshInstance3D.new()
	var dot := SphereMesh.new()
	dot.radius = 0.012
	dot.height = 0.024
	eye.mesh = dot
	eye.material_override = _mat("1a1a1a")
	eye.position = Vector3(-0.1, 0.015, 0.03)
	root.add_child(eye)
	root.scale = Vector3.ONE * clampf(size, 0.3, 2.0)
	if caught and caught.is_aberrant:
		var glow := body.material_override as StandardMaterial3D
		glow.emission_enabled = true
		glow.emission = color
		glow.emission_energy_multiplier = 1.5
	return root


static func _mat(hex: String) -> StandardMaterial3D:
	return _mat_color(Color(hex))


static func _mat_color(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.55
	return m
