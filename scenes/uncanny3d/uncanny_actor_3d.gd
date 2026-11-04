class_name UncannyActor3D
extends Node
## The uncanny toolkit for one person (PersonRig3D, PSX humanoid rig): a
## head that keeps facing Rin past the shoulder (stare_at), a pose held too
## long (freeze), a body moving at 6-8 fps in a 60 fps world (choppy), a
## face of pixel noise (glitch_face), the same face again on the back of
## the head (two_faces, TwoFace3D). Movement tricks: UncannyMoves3D.
## Survives the rig swapping its model (set_variant): re-attaches.
## attach(rig) adds it as the rig's child "Uncanny".

signal moved(to: Vector3)

const NODE_NAME := "Uncanny"
## Head centre above the Head bone origin (m, in the rig's scale).
const HEAD_UP := 0.11
const GLITCH_SIZE := 0.3
## The noise sits this far in front of the head, towards the camera.
const GLITCH_FORWARD := 0.13

var rig: PersonRig3D
var look: UncannyHeadLook3D
var hold: UncannyPoseHold3D
var glitch: MeshInstance3D
var _skeleton: Skeleton3D
var _target: Node3D
var _target_point := Vector3.ZERO
var _staring := false
var _frozen_left := 0.0
var _glitch_on := false


static func attach(person: PersonRig3D) -> UncannyActor3D:
	var existing := person.get_node_or_null(NODE_NAME) as UncannyActor3D
	if existing:
		return existing
	var actor := UncannyActor3D.new()
	actor.name = NODE_NAME
	actor.rig = person
	person.add_child(actor)
	return actor


func _ready() -> void:
	_rebuild()


func skeleton() -> Skeleton3D:
	var visual := rig.visual()
	return visual.skeleton if visual else null


## Keeps facing `target` (a Node3D, e.g. the camera) with neck + head, up to
## max_deg either side of the body. null = look ahead again.
func stare_at(target: Node3D, max_deg: float = 150.0, fade: float = 0.25) -> void:
	_target = target
	_staring = target != null
	if look:
		look.max_deg = max_deg
		_fade(look, 1.0 if _staring else 0.0, fade)


## Stare at a fixed world point.
func stare_at_point(point: Vector3, max_deg: float = 150.0) -> void:
	_target = null
	_target_point = point
	_staring = true
	if look:
		look.max_deg = max_deg
		_fade(look, 1.0, 0.25)


func stop_stare(fade: float = 0.4) -> void:
	stare_at(null, look.max_deg if look else 150.0, fade)


## Holds the whole pose (no breathing) for `seconds`; <= 0 = until release().
func freeze(seconds: float = 0.0) -> void:
	if hold:
		hold.freeze()
	_frozen_left = seconds if seconds > 0.0 else INF


## The body updates only `fps` times a second (6-8 = wrong).
func choppy(fps: float = 7.0) -> void:
	_frozen_left = 0.0
	if hold:
		hold.choppy(fps)


func release() -> void:
	_frozen_left = 0.0
	if hold:
		hold.release()


func is_frozen() -> bool:
	return hold != null and hold.mode == UncannyPoseHold3D.Mode.FREEZE


## Head region turns to jittering pixel noise; the body stays clean.
func glitch_face(on: bool) -> void:
	_glitch_on = on
	if glitch:
		glitch.visible = on
	if look:
		look.jitter = 0.09 if on else 0.0
		if on and look.influence < 1.0 and not _staring:
			look.influence = 1.0


## A second face on the back of the head, shown only while Rin is behind
## and not looking (TwoFace3D); now = at once (review). Returns the node.
func two_faces(on: bool, now := false) -> TwoFace3D:
	var faces := TwoFace3D.attach(rig)
	faces.set_wanted(on, now)
	return faces


func head_position() -> Vector3:
	var sk := skeleton()
	if sk == null:
		return rig.global_position + Vector3.UP * 1.6
	var head := sk.find_bone("Head")
	if head < 0:
		return rig.global_position + Vector3.UP * 1.6
	return sk.global_transform * sk.get_bone_global_pose(head).origin + Vector3.UP * HEAD_UP * rig.global_basis.get_scale().y


func _process(delta: float) -> void:
	if skeleton() != _skeleton:
		_rebuild()
	if look:
		look.body_forward = rig.global_basis.z.normalized()
		look.has_target = _staring or _glitch_on
		if _staring:
			look.target = _target.global_position if is_instance_valid(_target) else _target_point
		elif _glitch_on:
			look.target = rig.global_position + rig.global_basis.z * 3.0 + Vector3.UP * 1.6
	if _frozen_left > 0.0 and _frozen_left != INF:
		_frozen_left -= delta
		if _frozen_left <= 0.0:
			release()
	if glitch and glitch.visible:
		var head := head_position()
		var camera := get_viewport().get_camera_3d()
		var toward := (camera.global_position - head).normalized() if camera else rig.global_basis.z
		glitch.global_position = head + toward * GLITCH_FORWARD


## (Re)adds the modifiers under the current skeleton.
func _rebuild() -> void:
	_skeleton = skeleton()
	var mode := UncannyPoseHold3D.Mode.OFF
	var fps := 7.0
	if hold:
		mode = hold.mode
		fps = hold.fps
	var influence := look.influence if look else 0.0
	for old: Node in [look, hold]:
		if is_instance_valid(old):
			old.queue_free()
	look = null
	hold = null
	if _skeleton == null:
		return
	look = UncannyHeadLook3D.new()
	look.name = "UncannyLook"
	look.influence = influence
	_skeleton.add_child(look)
	hold = UncannyPoseHold3D.new()
	hold.name = "UncannyHold"
	_skeleton.add_child(hold)
	if mode == UncannyPoseHold3D.Mode.FREEZE:
		hold.freeze()
	elif mode == UncannyPoseHold3D.Mode.CHOPPY:
		hold.choppy(fps)
	if glitch == null:
		glitch = MeshInstance3D.new()
		glitch.name = "FaceGlitch"
		var quad := QuadMesh.new()
		quad.size = Vector2.ONE * GLITCH_SIZE
		glitch.mesh = quad
		var material := ShaderMaterial.new()
		material.shader = preload("res://scenes/uncanny3d/uncanny_face_glitch.gdshader")
		glitch.material_override = material
		glitch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		rig.add_child(glitch)
		glitch.top_level = true
	glitch.visible = _glitch_on
	if _glitch_on:
		glitch_face(true)


func _fade(modifier: SkeletonModifier3D, to: float, seconds: float) -> void:
	if seconds <= 0.0 or not is_inside_tree():
		modifier.influence = to
		return
	create_tween().tween_property(modifier, "influence", to, seconds)
