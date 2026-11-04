class_name SeaLayout3D
extends RefCounted
## The original 2D sea map (1920x1280 px) laid out in 3D world
## units. One unit = PX_PER_UNIT map pixels, centred on the map. Pure data:
## zones, places, rocks and the depth / boat-range maths. Map coordinates
## (phone map, pins) stay in the 2D pixel space.

const PX_PER_UNIT: float = 12.0
const MAP_PX := Vector2(1920, 1280)
const SHORE_PX: float = 1160.0
const DEEP_PX: float = 0.0
## Rects in map pixels, same as the 2D `Zones` node.
const OPEN_RECT := Rect2(0, 0, 1920, 560)
const REEF_RECT := Rect2(0, 560, 1920, 340)
const NEAR_RECT := Rect2(0, 900, 1920, 260)
const FOG_RECT := Rect2(1460, 0, 460, 420)
const SPOT_COUNT := {FishData.Zone.NEARSHORE: 4, FishData.Zone.REEF: 4, FishData.Zone.OPEN_SEA: 4, FishData.Zone.FOG: 3}
## Places and landmarks, map pixels.
const DOCK_PX := Vector2(1000, 1100)
const SHRINE_PX := Vector2(1350, 1135)
const HUT_PX := Vector2(480, 345)
const LIGHTHOUSE_PX := Vector2(1450, 262)
const RAFT_PX := Vector2(1400, 800)
const WHIRLPOOL_PX := Vector2(1720, 190)
## [x, y, radius] of the 2D reef / shore rocks.
const ROCKS_PX := [[260, 700, 18], [320, 650, 12], [700, 780, 22], [1150, 640, 16],
	[1210, 700, 24], [1650, 760, 18], [1550, 1000, 14]]
## [x, y, radius] of the 2D submerged rocks (đá ngầm): only seen inside the lamp's reach.
const SUBMERGED_PX := [[400, 820, 12], [620, 700, 10], [880, 850, 9], [980, 610, 13],
	[1300, 870, 10], [1520, 640, 12], [1780, 860, 11], [170, 600, 10], [760, 420, 14],
	[1100, 300, 12], [300, 160, 11], [1700, 520, 13]]


## Flat direction from the dock to the lobster raft (the village's sea shares these axes).
static func raft_bearing() -> Vector3:
	return (to_world(RAFT_PX) - to_world(DOCK_PX)).normalized()


static func to_world(px: Vector2) -> Vector3:
	return Vector3((px.x - MAP_PX.x * 0.5) / PX_PER_UNIT, 0.0, (px.y - MAP_PX.y * 0.5) / PX_PER_UNIT)


static func to_map(pos: Vector3) -> Vector2:
	return Vector2(pos.x * PX_PER_UNIT + MAP_PX.x * 0.5, pos.z * PX_PER_UNIT + MAP_PX.y * 0.5)


static func size_world() -> Vector2:
	return MAP_PX / PX_PER_UNIT


static func rect_world(rect: Rect2) -> Rect2:
	return Rect2(Vector2(to_world(rect.position).x, to_world(rect.position).z), rect.size / PX_PER_UNIT)


static func rocks() -> Array[Dictionary]:
	return _rock_list(ROCKS_PX)


static func submerged_rocks() -> Array[Dictionary]:
	return _rock_list(SUBMERGED_PX)


static func _rock_list(src: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r: Array in src:
		out.append({"pos": to_world(Vector2(float(r[0]), float(r[1]))), "radius": float(r[2]) / PX_PER_UNIT})
	return out


## Fishing zone at a world point (the fog sits over the open sea once open).
static func zone_at(pos: Vector3, fog_open: bool) -> FishData.Zone:
	var px := to_map(pos)
	if fog_open and FOG_RECT.has_point(px):
		return FishData.Zone.FOG
	if OPEN_RECT.has_point(px) or px.y < OPEN_RECT.end.y:
		return FishData.Zone.OPEN_SEA
	if REEF_RECT.has_point(px) or px.y < REEF_RECT.end.y:
		return FishData.Zone.REEF
	return FishData.Zone.NEARSHORE


static func zone_rect(zone: FishData.Zone) -> Rect2:
	match zone:
		FishData.Zone.OPEN_SEA: return OPEN_RECT
		FishData.Zone.REEF: return REEF_RECT
		FishData.Zone.FOG: return FOG_RECT
	return NEAR_RECT


## 0 at the shore, 1 at the far edge (same as the 2D spawner's depth).
static func depth_at(pos: Vector3) -> float:
	return CatchRoll.depth_at(to_map(pos).y, SHORE_PX, DEEP_PX)


## Northmost world z the boat may sail (BoatRange: lerp(shore, deep, max_depth)).
static func reach_z(max_depth: float) -> float:
	if max_depth >= 1.0:
		return -INF
	return to_world(Vector2(0, lerpf(SHORE_PX, DEEP_PX, max_depth))).z
