class_name VillageProps3D
extends RefCounted
## Places a village prop by id: the real model when one exists
## (assets/models/ready/<id>/<id>_reduced.glb + its concept -> ConceptModel3D,
## else a batch <id>/<id>.glb), otherwise a low-poly stand-in from
## VillageStandins3D. So models delivered later (coconut_palm, tube_house_a,
## motorbike_cub...) show up without code changes. Colliders stay separate.

const READY := "res://assets/models/ready/%s/%s"
const CONCEPT := "res://assets/concepts/horror/%s.png"

static var _known: Dictionary = {}  # id -> "concept" / "batch" / ""


## What `id` resolves to: "concept", "batch" or "" (stand-in).
static func kind(id: String) -> String:
	if _known.has(id):
		return _known[id]
	var found := ""
	if ResourceLoader.exists(READY % [id, id + "_reduced.glb"]) and ResourceLoader.exists(CONCEPT % id):
		found = "concept"
	elif ResourceLoader.exists(READY % [id, id + ".glb"]):
		found = "batch"
	_known[id] = found
	return found


## The prop standing at `at` (ground), fitted inside `size` metres, turned `yaw`.
## Stand-ins draw into `batch` when given (one mesh per material for the lot).
static func place(parent: Node3D, id: String, at: Vector3, size: Vector3, yaw: float = 0.0, batch: BoxBatch3D = null) -> void:
	match kind(id):
		"concept":
			if ConceptModel3D.geometry(id).has("size"):
				ConceptModel3D.fit(parent, id, at, size, yaw)
			else:
				ConceptModel3D.spawn(parent, id, at, size.y, yaw)
		"batch":
			fit_scene(parent, load(READY % [id, id + ".glb"]) as PackedScene, at, size, yaw)
		_:
			var own := batch == null
			var b := BoxBatch3D.new() if own else batch
			VillageStandins3D.build(b, id, at, size, yaw)
			if own:
				b.commit(parent, "Standin_" + id)


## A plain scene scaled uniformly to fit `size`, standing on `at`.
static func fit_scene(parent: Node3D, scene: PackedScene, at: Vector3, size: Vector3, yaw: float = 0.0) -> Node3D:
	var model := scene.instantiate() as Node3D
	var root := Node3D.new()
	parent.add_child(root)
	root.add_child(model)
	var bounds := AABB()
	var first := true
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var box := model.global_transform.affine_inverse() * mesh.global_transform * mesh.get_aabb() if mesh.is_inside_tree() else mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	var s := minf(size.x / maxf(bounds.size.x, 0.01), minf(size.y / maxf(bounds.size.y, 0.01), size.z / maxf(bounds.size.z, 0.01)))
	model.scale = Vector3.ONE * s
	model.position = Vector3(-bounds.get_center().x * s, -bounds.position.y * s, -bounds.get_center().z * s)
	root.position = at
	root.rotation.y = yaw
	WorldPresentation3D.cast_shadows(root)
	return root
