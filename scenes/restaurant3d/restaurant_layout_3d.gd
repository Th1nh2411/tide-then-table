class_name RestaurantLayout3D
extends RefCounted
## Fixed positions and room bounds of the 3D restaurant (x and z edges; the camera sees all of it).

const TABLES := [
	# First 4 = 2x2 nearest the stove (as in the 2D map); upgrades add rows above and below.
	Vector3(-5.5, 0, -2.0), Vector3(-9.5, 0, -2.0),
	Vector3(-5.5, 0, 1.4), Vector3(-9.5, 0, 1.4),
	Vector3(-5.5, 0, -5.4), Vector3(-9.5, 0, -5.4),
	Vector3(-5.5, 0, 4.8), Vector3(-9.5, 0, 4.8),
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
const BOARD_POSITION := Vector3(1.5, 0, 6.9)
const PASS_POSITION := Vector3(-0.8, 0, -4.3)
const GRILL_POSITION := Vector3(3.0, 0, -4.3)
const BEER_POSITION := Vector3(5.2, 0, -3.7)
