class_name VillageLayout3D
extends RefCounted
## Where things are on the one village map (VillageScene3D), in world metres.
## The restaurant street keeps its own coordinates (RestaurantLayout3D, x
## -20..20); its east end opens onto the lane (x 20..47), which ends on the
## waterfront (WaterfrontBuilder3D at WATERFRONT, sea towards -Z). Rin's room
## (BedroomBuilder3D at ROOM) is the house on the waterfront: its door is the
## waterfront's DOOR.

const SCENE := "res://scenes/village3d/village_scene_3d.tscn"
## Gap in the street's east wall (z range) where the lane starts.
const EXIT_X := 20.0
const EXIT_Z := Vector2(1.0, 6.0)
const LANE_END_X := 47.0
const LANE_Z := 3.5
## WaterfrontBuilder3D origin: its lane sign (-14, 8) sits at the lane's end.
const WATERFRONT := Vector3(64.0, 0, -4.5)
## BedroomBuilder3D origin: room door (1.5, -2) == waterfront door (-1, 9.4).
const ROOM := Vector3(61.5, 0, 6.9)
## Rin is "at the restaurant" west of this (the shift opens on the first visit).
const SHIFT_X := 18.0
## Waterfront ground (x / z ranges) and the pier strip out to the thúng.
const GROUND_X := Vector2(47.0, 81.0)
const GROUND_Z := Vector2(-2.5, 9.5)
const PIER_X := Vector2(69.1, 70.9)
const PIER_START_Z := WATERFRONT.z + WaterfrontBuilder3D.PIER_START_Z
const PIER_END_Z := WATERFRONT.z + WaterfrontBuilder3D.PIER_END_Z
## The beach (ShoreBeach3D) runs on east of the waterfront to this world x.
const BEACH_END_X := 240.0
## Walkers stop here on the beach's slope, just above the waterline; west
## of BEACH_WEST_X (the headland's sloped corner) at the old shore line.
const BEACH_STOP_Z := -4.3
const BEACH_WEST_X := 50.0


static func room_point(local: Vector3) -> Vector3:
	return ROOM + local


static func waterfront_point(local: Vector3) -> Vector3:
	return WATERFRONT + local


## Waking spot in the room, and the pier spot when Rin rows back at night.
static func morning_start() -> Vector3:
	return room_point(BedroomBuilder3D.START)


static func pier_start() -> Vector3:
	return waterfront_point(WaterfrontBuilder3D.THUNG) + Vector3(0, 0, 2.2)


static func in_room(p: Vector3) -> bool:
	var half := BedroomBuilder3D.HALF
	return absf(p.x - ROOM.x) < half.x and absf(p.z - ROOM.z) < half.y


static func on_pier(p: Vector3) -> bool:
	return p.x > PIER_X.x and p.x < PIER_X.y and p.z < PIER_START_Z


## Sand height under a walker on the waterfront's beach, NAN elsewhere
## (and on the pier, whose planks sit at the sand's top).
static func beach_y(p: Vector3) -> float:
	if p.x < GROUND_X.x or p.x > GROUND_X.y or p.z > GROUND_Z.x + 1.0 or on_pier(p):
		return NAN
	var local := p - WATERFRONT
	return ShoreBeach3D.height_at(local.x, local.z, GROUND_X.y - WATERFRONT.x)


## "house", "street", "lane" or "waterfront" (sound and light zones).
static func area(p: Vector3) -> String:
	if in_room(p):
		return "house"
	if p.x < EXIT_X:
		return "street"
	if p.x < LANE_END_X:
		return "lane"
	return "waterfront"


## Footstep surface (Sfx.step): planks on the pier, sand by the sea, a dull
## scuff elsewhere (dirt lane, cement tiles in the room and the street).
static func surface(p: Vector3) -> String:
	if on_pier(p):
		return "wood"
	return "sand" if area(p) == "waterfront" else "dirt"
