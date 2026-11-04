class_name BikeRider3D
extends RefCounted
## Guests on a CustomerTraffic3D bike: where the driver and the pillion sit,
## the riding pose (the rig's sit clip lifted onto the seat) and getting off /
## back on at the curb. People are the traffic's walker holders (a Node3D with
## a "WalkerActor" PersonRig3D); while on the bike they are its children.

## Bike-local seats (the model faces +Z). y lifts the sit clip (hips at
## RestaurantSeating3D.SEAT_HEIGHT) onto the saddle; feet land on the floorboard.
const SEATS: Array[Vector3] = [Vector3(0, 0.3, -0.3), Vector3(0, 0.34, -0.7)]
## Women ride pillion side-saddle (yaw relative to the bike, legs out to the side).
const SIDE_SADDLE_YAW := PI * 0.5
const SIDE_SADDLE_SHIFT := Vector3(-0.08, 0.02, 0.1)
## Where each one stands beside the parked bike (bike-local); side-saddle
## riders step off forward on their leg side.
const STEP_OFF: Array[Vector3] = [Vector3(0.62, 0, -0.25), Vector3(-0.62, 0, -0.7)]
const SIDE_SADDLE_STEP_OFF := Vector3(0.6, 0, -0.75)
## Getting off / on takes this long (the stand-up / sit-down clips).
const SECONDS := 0.7
## The driver's clip: the sit clip with the arms reaching for the handlebar
## (extra pitch in radians on top of SeatedAnimation3D's arms).
const RIDE_CLIP := "RideIdle"
const REACH_UPPER_ARM := -0.8
const REACH_FOREARM := 1.1


static func actor(person: Node3D) -> PersonRig3D:
	return person.get_node("WalkerActor") as PersonRig3D


## Seat position and yaw (bike-local) for rider `index` (0 driver, 1 pillion).
static func seat(person: Node3D, index: int) -> Vector3:
	if index == 1 and _side_saddle(person):
		return SEATS[1] + SIDE_SADDLE_SHIFT
	return SEATS[mini(index, 1)]


static func seat_yaw(person: Node3D, index: int) -> float:
	return SIDE_SADDLE_YAW if index == 1 and _side_saddle(person) else 0.0


## Straight onto the seat (riding in from the street end).
static func mount(person: Node3D, bike: Node3D, index: int) -> void:
	attach(person, bike)
	person.position = seat(person, index)
	person.rotation = Vector3(0, seat_yaw(person, index), 0)
	settle(person, index)


## Riding pose once on the seat: hands on the handlebar for the driver.
static func settle(person: Node3D, index: int) -> void:
	var rig := actor(person)
	rig.set_seated(true)
	if index == 0 and rig.visual() and _ride_clip(rig.visual()):
		rig.visual().set_motion(RIDE_CLIP)


## Parents `person` to the bike, keeping where it stands; its blob shadow hides.
static func attach(person: Node3D, bike: Node3D) -> void:
	if person.get_parent() != bike:
		person.reparent(bike, true)
	_shadow(person, false)


## Back to walking under `parent` (the traffic node), upright.
static func detach(person: Node3D, parent: Node3D) -> void:
	person.reparent(parent, true)
	person.rotation = Vector3(0, person.rotation.y, 0)
	person.position.y = 0.0
	actor(person).set_seated(false)
	_shadow(person, true)


## Getting off, t 0..1: seat -> beside the bike, stand-up clip.
static func sample_off(person: Node3D, index: int, t: float) -> void:
	var k := smoothstep(0.0, 1.0, t)
	person.position = seat(person, index).lerp(step_off(person, index), k)
	person.rotation.y = seat_yaw(person, index)  # stands up facing as seated
	actor(person).sample_seating(t, true)


## Getting on, t 0..1: from `from` (bike-local, where it stood) -> seat, sit-down clip.
static func sample_on(person: Node3D, index: int, from: Vector3, from_yaw: float, t: float) -> void:
	var k := smoothstep(0.0, 1.0, t)
	person.position = from.lerp(seat(person, index), k)
	person.rotation.y = lerp_angle(from_yaw, seat_yaw(person, index), k)
	actor(person).sample_seating(t)
	if t >= 1.0:
		settle(person, index)


## Bike-local spot rider `index` gets off to / gets on from.
static func step_off(person: Node3D, index: int) -> Vector3:
	return SIDE_SADDLE_STEP_OFF if index == 1 and _side_saddle(person) else STEP_OFF[mini(index, 1)]


## The same spot in the bike's parent space (walk targets).
static func step_point(bike: Node3D, person: Node3D, index: int) -> Vector3:
	var p := bike.transform * step_off(person, index)
	return Vector3(p.x, 0, p.z)


## Builds RIDE_CLIP once per animation player from its SitIdle (per model:
## the arm axes come from that skeleton's sitting pose).
static func _ride_clip(visual: RinPilotVisual) -> bool:
	var player := visual.animation
	if player.has_animation(RIDE_CLIP):
		return true
	if not player.has_animation("SitIdle"):
		return false
	visual.sample_motion("SitIdle", 0.0)
	var sk := visual.skeleton
	var clip := player.get_animation("SitIdle").duplicate(true) as Animation
	for part: String in ["UpperArm.", "Forearm."]:
		for side: String in ["L", "R"]:
			var bone := visual.bone(part + side)
			if bone < 0:
				continue
			var axis := (sk.get_bone_global_pose(bone).basis.orthonormalized().inverse() * Vector3.RIGHT).normalized()
			var turn := Quaternion(axis, REACH_UPPER_ARM if part == "UpperArm." else REACH_FOREARM)
			var suffix := ":" + sk.get_bone_name(bone)
			for track in clip.get_track_count():
				if clip.track_get_type(track) == Animation.TYPE_ROTATION_3D and str(clip.track_get_path(track)).ends_with(suffix):
					for key in clip.track_get_key_count(track):
						var q: Quaternion = clip.track_get_key_value(track, key)
						clip.track_set_key_value(track, key, q * turn)
	player.get_animation_library("").add_animation(RIDE_CLIP, clip)
	return true


## Even guest ids are women (PersonRig3D.next_guest_variant).
static func _side_saddle(person: Node3D) -> bool:
	var id := actor(person).get_variant().trim_prefix("guest_")
	return id.is_valid_int() and int(id) % 2 == 0


static func _shadow(person: Node3D, on: bool) -> void:
	var shadow := actor(person).get_node_or_null("ContactShadow") as Node3D
	if shadow:
		shadow.visible = on
