class_name TargetPulse3D
extends Node
## Soft warm pulse on one 3D thing (the next goal) instead of text labels:
## an additive overlay material on its meshes, fading in and out slowly.
## Works while the tree is paused too (process always), so panels don't freeze it mid-glow.

const COLOR := Color("f2d98a")
## Peak overlay strength and seconds per pulse.
@export var strength: float = 0.4
@export var period: float = 1.4

var _target: Node3D
var _meshes: Array[MeshInstance3D] = []
var _material := StandardMaterial3D.new()
var _clock: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_material.albedo_color = Color(COLOR, 0.0)


## Pulses `node` (null = nothing). Same node again keeps the pulse running.
func set_target(node: Node3D) -> void:
	if node == _target:
		return
	_clear()
	_target = node
	_clock = 0.0
	if node == null:
		return
	for mesh: Node in node.find_children("*", "MeshInstance3D", true, false):
		var instance := mesh as MeshInstance3D
		if instance.material_overlay == null and instance.visible:
			instance.material_overlay = _material
			_meshes.append(instance)


func target() -> Node3D:
	return _target


func _process(delta: float) -> void:
	if _target == null:
		return
	if not is_instance_valid(_target):
		_target = null
		_meshes.clear()
		return
	_clock += delta
	# 0 -> peak -> 0, eased so it reads as breathing, not blinking.
	var wave := 0.5 - 0.5 * cos(TAU * _clock / period)
	_material.albedo_color.a = strength * wave


func _clear() -> void:
	for mesh in _meshes:
		if is_instance_valid(mesh) and mesh.material_overlay == _material:
			mesh.material_overlay = null
	_meshes.clear()
