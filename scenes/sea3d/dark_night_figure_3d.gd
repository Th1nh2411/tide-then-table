class_name DarkNightFigure3D
extends Node3D
## Something at the edge of the lamp on đêm âm (DarkNight3D). STAND: a
## drowned person (GhostCast3D) standing on the water, pale eyes. SWIM: only
## the head and eyes gliding sideways, the body under the water. Either one
## is gone the moment Rin looks straight at it (or when its time is up,
## sinking quietly).

signal vanished(seen: bool)

enum Kind { STAND, SWIM }

const SWIM_HEAD_Y := 0.08

@export var look_angle_deg := 13.0
@export var fade_seconds := 0.18
@export var lifetime := 9.0
@export var swim_speed := 1.4
@export var eye_color := Color("dfe9e2")

var kind := Kind.STAND
var swim_dir := Vector3.RIGHT
var _age := 0.0
var _leaving := false
var _materials: Array[StandardMaterial3D] = []
var _rig: PersonRig3D


func _ready() -> void:
	# A drowned body from the ghost cast; swimming, only its head is above water.
	_rig = GhostCast3D.figure(self, "", true)
	var head := to_local(GhostCast3D.actor_of(_rig).head_position())
	var head_y := head.y
	if kind == Kind.SWIM:
		_rig.position.y = SWIM_HEAD_Y - head.y
		head_y = SWIM_HEAD_Y
	var eye := SphereMesh.new()
	eye.radius = 0.018
	eye.height = 0.036
	for side: float in [-0.035, 0.035]:
		_part(eye, Vector3(side, head_y - 0.03, head.z + 0.1), eye_color, true)


func _process(delta: float) -> void:
	if _leaving:
		return
	_age += delta
	if kind == Kind.SWIM:
		position += swim_dir * swim_speed * delta
	var camera := get_viewport().get_camera_3d()
	if camera:
		var to_me := global_position + Vector3.UP * 1.0 - camera.global_position
		var facing := Vector3(to_me.x, 0.0, to_me.z)
		if facing.length() > 0.1:
			rotation.y = atan2(-facing.x, -facing.z)
		if (-camera.global_basis.z).angle_to(to_me) < deg_to_rad(look_angle_deg):
			vanish(true)
			return
	if _age > lifetime:
		vanish(false)


## Seen: gone in a blink. Not seen: slips under the water.
func vanish(seen: bool) -> void:
	if _leaving:
		return
	_leaving = true
	var tween := create_tween().set_parallel()
	for material in _materials:
		tween.tween_property(material, "albedo_color:a", 0.0, fade_seconds if seen else 1.2)
	GhostCast3D.fade(tween, _rig, 0.0, fade_seconds if seen else 1.2)
	if not seen:
		tween.tween_property(self, "position:y", position.y - 1.6, 1.2)
	await tween.finished
	vanished.emit(seen)
	queue_free()


func _part(mesh: PrimitiveMesh, at: Vector3, color: Color, glows: bool) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.disable_fog = glows
	_materials.append(material)
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	node.position = at
