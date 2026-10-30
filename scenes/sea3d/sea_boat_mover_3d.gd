class_name SeaBoatMover3D
extends RefCounted
## Steering the 3D boat for one physics frame: rowed boats push only while a
## stroke pulls (RowStroke), motor boats accelerate; wind away from the dock,
## a worn hull or a towed boat slows it, collisions damage the hull, the
## boat's range (max_depth) pushes it back, the map edge clamps it.
## State stays on the sea scene (velocity, yaw_velocity, row...): other
## helpers read it.

const BOAT_RANGE_LINE := "Sóng ngoài khơi đẩy thuyền trở lại."


## Moves the boat. Returns [forward, forward_speed] for the animation, or
## an empty array when the hull broke (the trip has ended).
static func drive(sea: SeaScene3D, delta: float) -> Array:
	var boat := sea.boat
	var data := sea.boat_data
	sea.impact_cooldown = maxf(sea.impact_cooldown - delta, 0.0)
	var forward := Vector3.FORWARD.rotated(Vector3.UP, boat.rotation.y)
	var throttle := Input.get_axis("throttle_back", "throttle_forward")
	var steer := Input.get_axis("turn_left", "turn_right")
	if not sea._application_focused or sea._wait_controls_release:
		if sea._application_focused and not sea._movement_controls_held():
			sea._wait_controls_release = false
		throttle = 0.0
		steer = 0.0
	var condition := lerpf(0.6, 1.0, clampf(GameState.boat_hp / 50.0, 0.0, 1.0)) * (0.65 if sea._is_towing() else 1.0)
	if data.rowed:
		# Paddled: pushed only while a stroke pulls, then it glides and spins down.
		var push := sea.row.step(delta, throttle, steer, data)
		boat.velocity += forward * push.x * condition
		sea.yaw_velocity += push.y
		boat.velocity *= exp(-data.glide_drag * delta)
		sea.yaw_velocity *= exp(-data.spin_drag * delta)
	else:
		boat.velocity += forward * throttle * data.acceleration / 10.0 * delta
		boat.velocity *= exp(-1.15 * delta)
	if not sea._at_dock():
		boat.velocity += sea.wind * delta
	boat.velocity = boat.velocity.limit_length(data.max_speed / 10.0 * condition)
	var forward_speed := boat.velocity.dot(forward)
	if not data.rowed:
		var turn_target := steer * deg_to_rad(data.turn_speed) * (0.35 + minf(absf(forward_speed) / 8.0, 0.65))
		sea.yaw_velocity = move_toward(sea.yaw_velocity, turn_target, delta * (3.0 - data.spin_drift))
	boat.rotation.y += sea.yaw_velocity * delta
	boat.velocity.y = 0.0
	var before := boat.position
	var impact_speed := boat.velocity.length()
	boat.move_and_slide()
	boat.position.y = 0.0
	if boat.get_slide_collision_count() > 0:
		if before.distance_to(boat.position) < 0.3 and impact_speed > 2.0 and sea.impact_cooldown <= 0.0:
			BoatCondition.damage(minf(14.0, impact_speed * 1.6) * sea.blessed_damage_scale)
			sea.impact_cooldown = 0.85
			sea._say("Mạn thuyền va vào vật cản!", 1.8)
		boat.velocity *= 0.45
		if GameState.boat_hp <= 0.0:
			sea._say("Thuyền hỏng rồi. Có người kéo Rin về bến.", 3.0)
			sea._end_trip(true)
			return []
	_keep_in_bounds(sea)
	return [forward, forward_speed]


## Boat range is inherited from the selected upgrade; the map edge clamps.
static func _keep_in_bounds(sea: SeaScene3D) -> void:
	var boat := sea.boat
	var min_z := SeaLayout3D.reach_z(sea.boat_data.max_depth)
	if boat.position.z < min_z:
		boat.position.z = min_z
		boat.velocity.z = maxf(boat.velocity.z, 0.0)
		sea._say(BOAT_RANGE_LINE, 1.5)
	var half := SeaLayout3D.size_world() * 0.5 - Vector2.ONE * 2.0
	boat.position.x = clampf(boat.position.x, -half.x, half.x)
	boat.position.z = clampf(boat.position.z, -half.y, SeaLayout3D.to_world(Vector2(0, SeaLayout3D.SHORE_PX)).z + 1.0)
