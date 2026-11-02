class_name SeaShoals3D
extends RefCounted
## Spawns tonight's fish shoals like the 2D FishingSpotSpawner: a few per zone
## at random free points, each with a featured species picked by zone + depth,
## a chance of a "big shadow", and a limited number of casts.

const MIN_FISH: int = 3
const MAX_FISH: int = 6
const BIG_MAX_FISH: int = 3
## Cap on school_count() (bubble density hints; the old minigame showed this many).
const SCHOOL_CAP: int = 6
const CLEARANCE_PX: float = 30.0
const MIN_DISTANCE_PX: float = 120.0
const ATTEMPTS: int = 30
const RARITY_BOOST: float = 3.0
const BIG_RARITY_BOOST: float = 8.0
const FEATURED_CHANCE: float = 0.7
const BIG_CHANCE_SHALLOW: float = 0.05
const BIG_CHANCE_DEEP: float = 0.4

class Shoal extends RefCounted:
	var pos := Vector3.ZERO
	var zone: FishData.Zone = FishData.Zone.NEARSHORE
	var depth: float = 0.0
	var fish_left: int = 3
	var max_fish: int = 3
	var big_shadow: bool = false
	var featured: FishData

	## Fish left, capped (kept for tests / hints).
	func school_count() -> int:
		return mini(fish_left, SCHOOL_CAP)

	## Featured species most casts, else a zone/depth random fish.
	func roll_fish(catalog: FishCatalog, rng: RandomNumberGenerator, rarity_bonus: float, species_bonus: Dictionary) -> FishData:
		if featured and rng.randf() < FEATURED_CHANCE:
			return featured
		return catalog.pick_random(zone, rng, FishData.CatchMethod.ROD, depth, RARITY_BOOST + rarity_bonus, species_bonus)


## `extra`: weather extra_spots per zone. Fog zone is skipped while locked.
static func spawn(catalog: FishCatalog, rng: RandomNumberGenerator, fog_open: bool, extra: int = 0,
		rarity_bonus: float = 0.0, species_bonus: Dictionary = {}) -> Array[Shoal]:
	var shoals: Array[Shoal] = []
	var zones: Array = [FishData.Zone.OPEN_SEA, FishData.Zone.REEF, FishData.Zone.NEARSHORE, FishData.Zone.FOG]
	for zone: FishData.Zone in zones:
		if zone == FishData.Zone.FOG and not fog_open:
			continue
		var rect: Rect2 = SeaLayout3D.zone_rect(zone).grow(-CLEARANCE_PX)
		for n in int(SeaLayout3D.SPOT_COUNT[zone]) + extra:
			for attempt in ATTEMPTS:
				var px := Vector2(rng.randf_range(rect.position.x, rect.end.x), rng.randf_range(rect.position.y, rect.end.y))
				var pos := SeaLayout3D.to_world(px)
				if SeaLayout3D.zone_at(pos, fog_open) == zone and _is_free(pos, shoals):
					shoals.append(_make(catalog, rng, pos, zone, rarity_bonus, species_bonus))
					break
	return shoals


static func _is_free(pos: Vector3, shoals: Array[Shoal]) -> bool:
	var min_d: float = MIN_DISTANCE_PX / SeaLayout3D.PX_PER_UNIT
	for s in shoals:
		if s.pos.distance_to(pos) < min_d:
			return false
	for px: Vector2 in [SeaLayout3D.DOCK_PX, SeaLayout3D.SHRINE_PX, SeaLayout3D.HUT_PX,
			SeaLayout3D.LIGHTHOUSE_PX, SeaLayout3D.RAFT_PX, SeaLayout3D.WHIRLPOOL_PX]:
		if SeaLayout3D.to_world(px).distance_to(pos) < min_d:
			return false
	for rock in SeaLayout3D.rocks() + SeaLayout3D.submerged_rocks():
		var rpos: Vector3 = rock["pos"]
		if rpos.distance_to(pos) < float(rock["radius"]) + CLEARANCE_PX / SeaLayout3D.PX_PER_UNIT:
			return false
	return true


static func _make(catalog: FishCatalog, rng: RandomNumberGenerator, pos: Vector3, zone: FishData.Zone,
		rarity_bonus: float, species_bonus: Dictionary) -> Shoal:
	var s := Shoal.new()
	s.pos = pos
	s.zone = zone
	s.depth = SeaLayout3D.depth_at(pos)
	s.fish_left = rng.randi_range(MIN_FISH, MAX_FISH)
	s.big_shadow = rng.randf() < lerpf(BIG_CHANCE_SHALLOW, BIG_CHANCE_DEEP, s.depth)
	if s.big_shadow:
		s.featured = catalog.pick_random(zone, rng, FishData.CatchMethod.ROD, 1.0, BIG_RARITY_BOOST + rarity_bonus, species_bonus)
		s.fish_left = mini(s.fish_left, BIG_MAX_FISH)
	else:
		s.featured = catalog.pick_random(zone, rng, FishData.CatchMethod.ROD, s.depth, RARITY_BOOST + rarity_bonus, species_bonus)
	s.max_fish = s.fish_left
	return s
