class_name UncannyScene3D
extends RefCounted
## Scene-level uncanny tricks: props that turn or move while Rin isn't
## looking (slippers turned to the sea, stools all facing one way), a door
## closed without a sound, one person too many between two looks, lights
## gone for two frames while someone changes pose. Sights with their own
## node: UncannyEyes3D (eyes in the dark), UncannyReflection3D (a figure
## only in the water). All of it is quiet: no stinger sounds.


## Turns `node` to `yaw` (radians, local) once it has been seen and is unseen.
static func turn_when_unseen(host: Node, node: Node3D, yaw: float) -> UnseenTrick3D:
	return UnseenTrick3D.watch(host, func(_s: int) -> void:
			if is_instance_valid(node):
				node.rotation.y = yaw,
		func(_s: int) -> Array[Vector3]:
			return [node.global_position + Vector3.UP * 0.3] as Array[Vector3])


## Turns all `nodes` to face `toward` (world point) in one unseen moment.
static func all_face_when_unseen(host: Node, nodes: Array[Node3D], toward: Vector3) -> UnseenTrick3D:
	return UnseenTrick3D.watch(host, func(_s: int) -> void:
			for node in nodes:
				if is_instance_valid(node):
					UncannyMoves3D.face_dir(node, toward - node.global_position),
		func(_s: int) -> Array[Vector3]:
			var at: Array[Vector3] = []
			for node in nodes:
				if is_instance_valid(node):
					at.append(node.global_position + Vector3.UP * 0.4)
			return at)


## Closes the door with no sound, while Rin is away and not looking at it.
static func close_door_unseen(host: Node, door: VillageDoor3D, gate: Callable = Callable()) -> UnseenTrick3D:
	var trick := UnseenTrick3D.watch(host, func(_s: int) -> void:
			if is_instance_valid(door) and door.is_open:
				door.set_open(false, false, true),
		func(_s: int) -> Array[Vector3]:
			return [door.aim_point(), door.aim_point() + door.global_basis.x * 0.9] as Array[Vector3],
		1, false)
	trick.gate = gate
	trick.unseen_seconds = 2.0
	return trick


## One person too many: shows at `at` between two looks, gone after the
## next one; `cycles` times. Returns the figure (hidden at first).
static func extra_figure(host: Node3D, at: Vector3, face: Vector3, kind: String = "guest", cycles: int = 2) -> PersonRig3D:
	var rig := PersonRig3D.build(host, kind)
	rig.global_position = at
	UncannyMoves3D.face_dir(rig, face - at)
	UncannyMoves3D.ghost_body(rig)
	rig.visible = false
	UnseenTrick3D.watch(rig, func(_s: int) -> void:
			rig.visible = not rig.visible,
		func(_s: int) -> Array[Vector3]:
			return [at + Vector3.UP * 0.2, at + Vector3.UP * 1.6] as Array[Vector3],
		cycles * 2)
	return rig


## All `lights` off for two frames; `change` runs in the dark (a pose, a
## turned head), so the lights come back on something different.
static func flicker_pose(host: Node, lights: Array[Node3D], change: Callable) -> void:
	var was: Array[bool] = []
	for light in lights:
		was.append(light.visible)
		light.visible = false
	change.call()
	await host.get_tree().process_frame
	await host.get_tree().process_frame
	for i in lights.size():
		if is_instance_valid(lights[i]):
			lights[i].visible = was[i]


## A pair of rubber slippers (dép tổ ong) on the floor, toes along +Z.
static func slippers(parent: Node3D, at: Vector3, yaw: float) -> Node3D:
	var pair := Node3D.new()
	pair.name = "Slippers"
	parent.add_child(pair)
	pair.global_position = at
	pair.rotation.y = yaw
	for side: float in [-0.07, 0.07]:
		OmenProps3D.box(pair, Vector3(side, 0.012, 0), Vector3(0.09, 0.024, 0.25), "2c4f6b")
		OmenProps3D.box(pair, Vector3(side, 0.03, 0.05), Vector3(0.09, 0.02, 0.03), "c2b59a")
	return pair


## Every light under `root` (to flicker).
static func lights_under(root: Node) -> Array[Node3D]:
	var found: Array[Node3D] = []
	for light: Node in root.find_children("*", "Light3D", true, false):
		if not light is DirectionalLight3D:
			found.append(light as Node3D)
	return found


## A dark figure built from primitives (no skeleton): body, head, pale eyes.
## `no_depth`: drawn over everything (the reflection).
static func silhouette(parent: Node3D, height: float, alpha: float, no_depth: bool = false) -> Node3D:
	var root := Node3D.new()
	root.name = "Silhouette"
	parent.add_child(root)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.03, 0.04, 0.04, alpha)
	dark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dark.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dark.no_depth_test = no_depth
	var torso := CapsuleMesh.new()
	torso.radius = height * 0.1
	torso.height = height * 0.42
	_part(root, torso, Vector3(0, height * 0.64, 0), dark)
	var limb := CapsuleMesh.new()
	limb.radius = height * 0.035
	limb.height = height * 0.5
	for side: float in [-1.0, 1.0]:
		_part(root, limb, Vector3(side * height * 0.055, height * 0.25, 0), dark)  # legs
		_part(root, limb, Vector3(side * height * 0.135, height * 0.6, 0), dark)  # arms hanging
	var head := SphereMesh.new()
	head.radius = height * 0.065
	head.height = height * 0.14
	_part(root, head, Vector3(0, height * 0.91, 0), dark)
	var pale := StandardMaterial3D.new()
	pale.albedo_color = Color(0.85, 0.9, 0.85, minf(alpha * 1.8, 1.0))
	pale.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pale.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pale.no_depth_test = no_depth
	pale.render_priority = 1
	var eye := SphereMesh.new()
	eye.radius = height * 0.009
	eye.height = height * 0.018
	for side: float in [-1.0, 1.0]:
		_part(root, eye, Vector3(side * height * 0.024, height * 0.915, height * 0.06), pale)
	return root


static func _part(root: Node3D, mesh: PrimitiveMesh, at: Vector3, material: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = material
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	part.position = at
	root.add_child(part)
	return part
