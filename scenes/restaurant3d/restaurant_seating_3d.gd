class_name RestaurantSeating3D
extends RefCounted
const APPROACH_SECONDS := .45
const SIT_SECONDS := .75
const STAND_SECONDS := .65
const SEAT_HEIGHT := .52*WorldPresentation3D.RESTAURANT_STOOL_SCALE

static func side(table: int) -> float:
	return -1.0 if table%2 == 0 else 1.0
static func seat(table: int, centre: Vector3) -> Vector3:
	return centre+Vector3(side(table)*1.02,0,0)
static func front(table: int, centre: Vector3) -> Vector3:
	return seat(table,centre)+Vector3(0,0,.36)
static func approach(table: int, centre: Vector3) -> Vector3:
	return seat(table,centre)+Vector3(0,0,1.12)
static func facing(table: int) -> float:
	return -side(table)*PI*.5
