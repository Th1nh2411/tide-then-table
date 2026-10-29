class_name RestaurantBatchVisuals
extends Node3D
## Canonical Hunyuan batch meshes; interaction/collision stays with the host.

var upgrade_id := ""
var variants: Array[Node3D] = []
var last_level := -1

static func add(parent: Node3D, id: String, at: Vector3) -> Node3D:
	var scene := load("res://assets/models/ready/%s/%s.glb" % [id, id]) as PackedScene
	var visual := scene.instantiate() as Node3D
	visual.name = "Batch_" + id
	parent.add_child(visual)
	visual.position = at
	WorldPresentation3D.cast_shadows(visual)
	return visual

static func upgrade(parent: Node3D, id: String, choices: Array, at: Vector3) -> RestaurantBatchVisuals:
	var group := RestaurantBatchVisuals.new()
	group.name = "BatchUpgrade_" + id
	group.upgrade_id = id
	parent.add_child(group)
	group.position = at
	for choice: String in choices:
		group.variants.append(add(group, choice, Vector3.ZERO))
	group._sync()
	return group

func _process(_delta: float) -> void:
	_sync()

func _sync() -> void:
	var level := GameState.get_upgrade_level(upgrade_id)
	if level == last_level:
		return
	last_level = level
	for i in range(variants.size()):
		variants[i].visible = i == clampi(level, 0, variants.size() - 1)

static func tint(root: Node3D, color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for mesh: Node in root.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).material_override = mat
