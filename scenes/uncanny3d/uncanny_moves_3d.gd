class_name UncannyMoves3D
extends RefCounted
## Movement that is wrong (UncannyActor3D's people): sliding without a step,
## walking backwards on forward-stepping legs, standing dead still then a
## sprint and a dead stop, and moving only while Rin isn't looking.


## Slides to `to` over `seconds` with the pose held (no step, no breath).
## `backwards`: faces away from where it goes, legs stepping forward.
static func wrong_walk(actor: UncannyActor3D, to: Vector3, seconds: float, backwards: bool = false) -> Tween:
	var rig := actor.rig
	var travel := to - rig.global_position
	travel.y = 0.0
	if backwards:
		actor.release()
		face_dir(rig, -travel)
		rig.set_walking(1.0, 0.0)
	else:
		actor.freeze()
	var tween := rig.create_tween()
	tween.tween_property(rig, "global_position", to, seconds)
	tween.tween_callback(func() -> void:
		rig.set_walking(0.0, 0.0)
		if not backwards:
			actor.release())
	return tween


## Stands frozen `wait` s, sprints to `to` in `duration` s, stops dead
## (pose held for `hold` s).
static func dash_to(actor: UncannyActor3D, to: Vector3, duration: float = 0.3, wait: float = 0.6, hold: float = 1.2) -> Tween:
	var rig := actor.rig
	actor.freeze()
	var tween := rig.create_tween()
	tween.tween_interval(wait)
	tween.tween_callback(func() -> void:
		actor.release()
		face_dir(rig, to - rig.global_position)
		rig.set_walking(1.5, 0.0))
	tween.tween_property(rig, "global_position", to, duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		rig.set_walking(0.0, 0.0)
		actor.freeze(hold))
	return tween


## Jumps to each of `spots` in turn, but only while it and the spot are out
## of Rin's view; faces `look_at` (e.g. the camera) after each jump.
static func move_when_unseen(actor: UncannyActor3D, spots: Array[Vector3], look_at: Node3D = null, seen_first: bool = true) -> UnseenTrick3D:
	var rig := actor.rig
	var points := func(step: int) -> Array[Vector3]:
		var to := spots[mini(step, spots.size() - 1)]
		var here := rig.global_position
		return [here + Vector3.UP * 0.2, here + Vector3.UP * 1.6, to + Vector3.UP * 0.2, to + Vector3.UP * 1.6] as Array[Vector3]
	var act := func(step: int) -> void:
		rig.global_position = spots[step]
		if is_instance_valid(look_at):
			face_dir(rig, look_at.global_position - rig.global_position)
		actor.moved.emit(spots[step])
	return UnseenTrick3D.watch(actor, act, points, spots.size(), seen_first)


## Turns the rig (+Z forward) to face a world direction (flat).
static func face_dir(rig: Node3D, dir: Vector3) -> void:
	var flat := Vector3(dir.x, 0.0, dir.z)
	if flat.length_squared() < 0.0001:
		return
	var parent := rig.get_parent_node_3d()
	if parent:
		flat = parent.global_basis.inverse() * flat
	rig.rotation.y = atan2(flat.x, flat.z)


## Removes a person's shadow (the guest who casts none) and its contact blob.
static func remove_shadow(rig: Node3D) -> void:
	for mesh: GeometryInstance3D in rig.find_children("*", "GeometryInstance3D", true, false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for decal: Node in rig.find_children("ContactShadow", "Decal", true, false):
		(decal as Decal).visible = false


## No collider: a ghost Rin may stand right beside must not block him.
static func ghost_body(rig: PersonRig3D) -> void:
	var blocker := rig.get_node_or_null("PersonBlocker") as StaticBody3D
	if blocker:
		blocker.collision_layer = 0
		blocker.collision_mask = 0
