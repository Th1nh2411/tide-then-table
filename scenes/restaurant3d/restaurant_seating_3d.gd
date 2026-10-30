class_name RestaurantSeating3D
extends RefCounted
const APPROACH_SECONDS := .45
const SIT_SECONDS := .75
const STAND_SECONDS := .65
const SEAT_HEIGHT := .52*WorldPresentation3D.RESTAURANT_STOOL_SCALE

static func side(table: int) -> float:
	return -1.0 if table%2 == 0 else 1.0
static func seat(table: int, centre: Vector3, opposite := false) -> Vector3:
	return centre+RestaurantLayout3D.chair_offset(side(table)*(-1 if opposite else 1))
static func front(table: int, centre: Vector3, opposite := false) -> Vector3:
	return seat(table,centre,opposite)+Vector3(0,0,.36)
static func approach(table: int, centre: Vector3, opposite := false) -> Vector3:
	return seat(table,centre,opposite)+Vector3(0,0,1.25)
static func facing(table: int, opposite := false) -> float:
	return -side(table)*(-1 if opposite else 1)*PI*.5
