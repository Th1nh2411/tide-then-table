class_name SeaEdge3D
extends RefCounted
## The night sea's edge, felt instead of told (no line): within MARGIN of the
## boat's reach (BoatData.max_depth) or the map's sides the fog thickens, the
## lamp dims (SeaTrip3D reads `sea.edge_amount`) and a current pushes the
## thúng back towards the dock; pressed all the way in, the bow swings round
## to the lighthouse on the village point. The hard clamp stays behind it.

const MARGIN := 12.0
## Current at the very edge (m/s per second), and how hard the bow turns home.
const PUSH := 3.2
const TURN := 1.6
const EXTRA_FOG := 0.09
const META := "sea_edge_fog"


## 0 inside, 1 at the edge: how deep the boat at `p` is in the edge band.
static func amount(p: Vector3, reach_z: float, half: Vector2) -> float:
	var over := maxf((reach_z + MARGIN) - p.z, (-half.y + MARGIN) - p.z)
	over = maxf(over, absf(p.x) - (half.x - MARGIN))
	return clampf(over / MARGIN, 0.0, 1.0)


## The village point's lighthouse, near the dock (SeaWorldBuilder3D builds it there).
static func home_light(sea: SeaScene3D) -> Vector3:
	return sea.START + Vector3(-7.8, 0, 6.3)


## One frame: fog, current and the bow's turn. Called by SeaBoatMover3D.
static func step(sea: SeaScene3D, delta: float) -> void:
	var boat := sea.boat
	var half := SeaLayout3D.size_world() * 0.5
	var t := amount(boat.position, SeaLayout3D.reach_z(sea.boat_data.max_depth), half)
	sea.edge_amount = t
	_fog(sea, t)
	if t <= 0.0:
		return
	var home := sea.START - boat.position
	home.y = 0.0
	boat.velocity += home.normalized() * PUSH * t * t * delta
	if t > 0.8:
		var to_light := home_light(sea) - boat.position
		var want := atan2(-to_light.x, -to_light.z)
		var turn := angle_difference(boat.rotation.y, want)
		sea.yaw_velocity = lerpf(sea.yaw_velocity, clampf(turn, -1.0, 1.0) * TURN, minf(delta * 4.0 * (t - 0.8) * 5.0, 1.0))


static func _fog(sea: SeaScene3D, t: float) -> void:
	var env: Environment = null
	for child in sea.get_children():
		if child is WorldEnvironment:
			env = (child as WorldEnvironment).environment
			break
	if env == null:
		return
	if not env.has_meta(META):
		env.set_meta(META, env.fog_density)
	var base: float = env.get_meta(META)
	env.fog_density = base + EXTRA_FOG * t * t
