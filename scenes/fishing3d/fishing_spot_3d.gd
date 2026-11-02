class_name FishingSpot3D
extends RefCounted
## Where the first-person line lands and what bites there (Fishing3D):
## the water under the crosshair, clamped to the cast reach and to water the
## thúng can reach; the shoal under the bobber; species + size from the
## shoal (CatchRoll), else from the zone.

const WATER_Y := 0.12


## The water point under the crosshair, tuning.cast_min..cast_max ahead.
static func aim(sea: SeaScene3D, tuning: ReelTuning, camera: Camera3D) -> Vector3:
	var dir := Vector3.FORWARD.rotated(Vector3.UP, sea.boat.rotation.y)
	var reach := tuning.cast_max
	if camera:
		var forward := -camera.global_basis.z
		if Vector2(forward.x, forward.z).length() > 0.01:
			dir = Vector3(forward.x, 0, forward.z).normalized()
		if forward.y < -0.02:
			var hit := camera.global_position + forward * ((camera.global_position.y - WATER_Y) / -forward.y)
			reach = flat_distance(sea, hit)
	reach = clampf(reach, tuning.cast_min, tuning.cast_max)
	return clamp_to_water(sea, sea.boat.global_position + dir * reach)


## Keeps a point on the sea: inside the boat's range, off the shore, on the map.
static func clamp_to_water(sea: SeaScene3D, p: Vector3) -> Vector3:
	p.z = maxf(p.z, SeaLayout3D.reach_z(sea.boat_data.max_depth) + 0.5)
	p.z = minf(p.z, SeaLayout3D.to_world(Vector2(0, SeaLayout3D.SHORE_PX)).z - 1.5)
	var half := SeaLayout3D.size_world() * 0.5 - Vector2.ONE * 2.0
	p.x = clampf(p.x, -half.x, half.x)
	p.z = maxf(p.z, -half.y)
	p.y = WATER_Y
	return p


static func shoal_at(sea: SeaScene3D, point: Vector3, radius: float) -> SeaShoals3D.Shoal:
	for shoal in sea.shoals:
		if shoal.fish_left > 0 and Vector2(shoal.pos.x - point.x, shoal.pos.z - point.z).length() < radius:
			return shoal
	return null


## [FishData or null, size]. A shoal gives its species (one fish leaves it).
static func roll(sea: SeaScene3D, shoal: SeaShoals3D.Shoal, point: Vector3) -> Array:
	var rng := sea.rng
	var fish: FishData
	var size := 1.0
	if shoal and shoal.fish_left > 0:
		fish = shoal.roll_fish(sea.fish_catalog, rng, 0.0, {})
		size = CatchRoll.roll_size(rng, shoal.depth, shoal.big_shadow)
		shoal.fish_left -= 1
	else:
		var depth := SeaLayout3D.depth_at(point)
		fish = sea.fish_catalog.pick_random(SeaLayout3D.zone_at(point, Story.is_fog_open()), rng,
			FishData.CatchMethod.ROD, depth, SeaShoals3D.RARITY_BOOST)
		size = CatchRoll.roll_size(rng, depth, false)
	if fish:
		size = CatchRoll.snap_size(size, fish.typical_kg)
	return [fish, size]


static func flat_distance(sea: SeaScene3D, point: Vector3) -> float:
	var at := sea.boat.global_position
	return Vector2(point.x - at.x, point.z - at.z).length()
