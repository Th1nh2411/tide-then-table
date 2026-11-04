class_name TwoFace3D
extends Node3D
## The same face once more on the back of a person's head, looking the other
## way (UncannyActor3D.two_faces). Not a picture: the face triangles of the
## model itself (vertices skinned to Head, in front of the head's centre) are
## copied once, turned 180° round the head's up axis, pushed out of the hair
## and hung on a BoneAttachment3D on Head, with the model's own materials (so
## StylePass3D / the PS1 look treat it like the body). It only shows while
## Rin is behind the person and the head is out of his sight (UnseenCheck),
## and goes again the same way once he has looked at it long enough.

signal shown
signal gone

const NODE_NAME := "TwoFace"
## A vertex counts as face this far ahead of the head's centre (share of the
## head's front radius) and when this much of its weight is on Head.
@export_range(0.0, 1.0) var face_from := 0.2
@export_range(0.0, 1.0) var head_weight := 0.6
## How far (m, head scale) the copy stands out of the back of the hair, and
## how much of its depth it keeps (flatter = sockets and lips stay outside).
@export var emerge := 0.012
@export_range(0.1, 1.0) var depth_keep := 0.45
## Rin is "behind" within this many degrees of the back of the head.
@export var behind_deg := 75.0
## Seconds Rin may look at it before it goes (at the next unseen moment).
@export var seen_for := 2.5

var rig: PersonRig3D
var wanted := false
var face: MeshInstance3D
var _attachment: BoneAttachment3D
var _skeleton: Skeleton3D
var _forward := Vector3.FORWARD  # head-bone space
var _centre := Vector3.ZERO  # head-bone space
var _looked := 0.0
var _offset := 0.0  # head space, along -forward
var _front := 0.0


static func attach(person: PersonRig3D) -> TwoFace3D:
	var existing := person.get_node_or_null(NODE_NAME) as TwoFace3D
	if existing:
		return existing
	var node := TwoFace3D.new()
	node.name = NODE_NAME
	node.rig = person
	person.add_child(node)
	return node


## on: show it the next time Rin is behind and not looking; now: right away.
func set_wanted(on: bool, now := false) -> void:
	wanted = on
	_looked = 0.0
	if now:
		_rebuild_if_needed()
		_set_shown(on)


func is_shown() -> bool:
	return face != null and face.visible


## World position of the back face's middle (where Rin would see it).
func face_position() -> Vector3:
	if _attachment == null:
		return rig.global_position + Vector3.UP * 1.6
	return _attachment.global_transform * (_centre - _forward * (_offset + _front))


func _process(delta: float) -> void:
	_rebuild_if_needed()
	if face == null:
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var unseen := unseen_by(camera)
	var behind := rin_behind(camera.global_position)
	if not face.visible:
		if wanted and unseen and behind:
			_set_shown(true)
		return
	if not unseen and behind:
		_looked += delta
	if unseen and (not wanted or _looked >= seen_for):
		wanted = false
		_set_shown(false)


## The back of the head is out of view or behind something (not the
## person's own blocker capsule, which wraps the head).
func unseen_by(camera: Camera3D) -> bool:
	var p := face_position()
	if not UnseenCheck.camera_sees(camera, p):
		return true
	var exclude: Array[RID] = []
	var blocker := rig.get_node_or_null("PersonBlocker") as CollisionObject3D
	if blocker:
		exclude.append(blocker.get_rid())
	return UnseenCheck.occluded(camera, p, exclude)


## Whether `eye` is behind the head (within behind_deg of its back).
func rin_behind(eye: Vector3) -> bool:
	if _attachment == null:
		return false
	var head := _attachment.global_transform * _centre
	var back := -(_attachment.global_basis * _forward)
	var to := eye - head
	to.y = 0.0
	back.y = 0.0
	if to.length_squared() < 0.0001 or back.length_squared() < 0.0001:
		return false
	return rad_to_deg(back.angle_to(to)) <= behind_deg


func _set_shown(on: bool) -> void:
	if face == null or face.visible == on:
		return
	face.visible = on
	if on:
		shown.emit()
	else:
		gone.emit()


func _rebuild_if_needed() -> void:
	var visual := rig.visual() if rig else null
	var skeleton := visual.skeleton if visual else null
	if skeleton == _skeleton:
		return
	var was := is_shown()
	if is_instance_valid(_attachment):
		_attachment.queue_free()
	_attachment = null
	face = null
	_skeleton = skeleton
	if skeleton == null or visual.model == null:
		return
	var head := visual.bone("Head")
	if head < 0:
		return
	_attachment = BoneAttachment3D.new()
	_attachment.name = "TwoFaceHead"
	skeleton.add_child(_attachment)
	_attachment.bone_name = skeleton.get_bone_name(head)
	# Rig space (faces +Z, up +Y) -> Head space at rest.
	var to_head := skeleton.get_bone_global_rest(head).basis.inverse() * skeleton.global_basis.inverse()
	_forward = (to_head * rig.global_basis.z).normalized()
	var up := (to_head * rig.global_basis.y).normalized()
	var copy := TwoFaceMesh.build(visual.model, skeleton, head, _forward, up, face_from, head_weight, depth_keep)
	if copy.is_empty():
		return
	_centre = copy["centre"]
	_front = copy["front"]
	face = MeshInstance3D.new()
	face.name = "BackFace"
	face.mesh = copy["mesh"]
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The turned face starts where the face was (front radius): out to the hair.
	_offset = float(copy["back"]) - float(copy["front"]) + emerge
	face.position = -_forward * _offset
	_attachment.add_child(face)
	face.visible = was
