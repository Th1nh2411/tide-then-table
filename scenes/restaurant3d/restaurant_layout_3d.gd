class_name RestaurantLayout3D
extends RefCounted
## Shared visual, interaction and navigation layout for the 3D restaurant.

const TABLES := [
	# Four tables in front of Rin's cart; extra leased bays extend to the left.
	Vector3(1.0,0,0.0), Vector3(4.6,0,0.0),
	Vector3(1.0,0,3.6), Vector3(4.6,0,3.6),
	Vector3(-4.0,0,0.0), Vector3(-4.0,0,3.6),
	Vector3(-7.6,0,0.0), Vector3(-7.6,0,3.6),
]
const ROOM_X := 20.0
const BACK_Z := -7.8
const WALL_H := 7.0
const FRONT_Z := 8.3
const ROAD_DEPTH := 8.0
const COUNTER_POSITION := Vector3(10.0, 0, -4.3)
const DECOR_LANTERNS: Array[float] = [-16.0, -12.0, -8.0, -4.0, 0.0, 4.0, 8.0, 12.0, 16.0]
const DECOR_PLANTERS: Array[float] = [-18.5, 18.5]
const PLANTER_Z := 7.3
## Street trees and the string-light pole stand on the pavement edge, not the road.
const CURB_PROP_Z := 7.7
const BOARD_POSITION := Vector3(6.2, 0, 5.8)
const KITCHEN_BOARD_POSITION := Vector3(5.8, 0, -1.7)
const PASS_POSITION := Vector3(-0.8, 0, -4.3)
const GRILL_POSITION := Vector3(3.0, 0, -4.3)
const BEER_POSITION := Vector3(5.2, 0, -3.7)


## Dining groups share one orientation across visuals, seating, collision and previews.
const TABLE_YAW := PI*.5
const TABLE_COLLISION_SIZE := Vector3(1.2,.12,1.5)
const TABLE_NAV_SIZE := Vector2(2.5,1.5)
const TABLE_SERVICE_OFFSET := Vector3(0,0,1.25)

static func table_offset(local: Vector3) -> Vector3:
	return local.rotated(Vector3.UP,TABLE_YAW)


const LEASE_LEFTS := [-3.0,-6.0,-10.0]
const LEASE_RIGHT := 14.0
const PUBLIC_WALK_Z := 6.2

static func lease_left(level: int) -> float:
	return LEASE_LEFTS[clampi(level,0,2)]

static func table_count(level: int) -> int:
	return 4+2*clampi(level,0,2)

static func staff_home(index: int) -> Vector3:
	return Vector3(-1.3,0,-1.8+float(index)*.7)


const CHAIR_OFFSET := .95
static func chair_offset(side: float) -> Vector3:
	return Vector3(side*CHAIR_OFFSET,0,0)
