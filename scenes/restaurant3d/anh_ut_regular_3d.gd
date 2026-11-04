class_name AnhUtRegular3D
extends Node3D
## Anh Út, the friendly regular (PLAN §10 "Mọi nhân vật đều có vai trò"):
## every shift from mùng 9 he sits at his own small table by the board (the
## spot where he pours the tea on rằm, RamGuest3D.TABLE), a bottle in front
## of him; E: one line a day (data/story/anh_ut.tres). He never orders, so
## Rin's and Vy's service is unchanged. On an omen night (he is out at the
## raft) his stool stays empty; from `ghost_from_day` a guest who casts no
## shadow sits there instead and turns to watch Rin. Not on rằm (RamGuest3D).

const LINES: NpcLinesData = preload("res://data/story/anh_ut.tres")
const NODE_NAME := "AnhUtRegular"
const TABLE := RamGuest3D.TABLE
const SEAT := TABLE + Vector3(0.95, 0, 0)
const REACH := 2.1
const GHOST_REACH := 2.4

## From this day (4 = 12 tháng Bảy) an omen night puts the shadowless guest on his stool.
@export var ghost_from_day := 4
@export var ghost_variant := "guest_7"
## 2 = mùng 10: he hands Rin the charm.
const CHARM_DAY := 2

var host: RestaurantScene3D
var ut: PersonRig3D
var ghost: PersonRig3D
var talk: NpcTalk3D
## Tonight is an omen night: he does not come.
var absent := false
var _bottle: Node3D
var _staring := false


static func attach(owner: RestaurantScene3D) -> AnhUtRegular3D:
	if RamNight.is_ram():
		return null
	var seat := AnhUtRegular3D.new()
	seat.name = NODE_NAME
	seat.host = owner
	owner.add_child(seat)
	return seat


func _ready() -> void:
	absent = GameState.has_flag(LoopCalendar.OMEN_FLAG)
	var table: Node3D = RestaurantRoomBuilder3D.TABLE_PILOT.instantiate()
	add_child(table)
	table.position = TABLE
	table.rotation.y = RestaurantLayout3D.TABLE_YAW
	RestaurantRoomBuilder3D.solid_block(self, TABLE + Vector3(0, 0.8, 0), RestaurantLayout3D.TABLE_COLLISION_SIZE)
	var stool: Node3D = RestaurantRoomBuilder3D.STOOL_PILOT.instantiate()
	add_child(stool)
	stool.position = SEAT
	stool.scale = Vector3.ONE * WorldPresentation3D.RESTAURANT_STOOL_SCALE
	if not absent:
		ut = _seated("guest_rich")
		_bottle = RestaurantBatchVisuals.add(self, "bottle", TABLE + Vector3(0.15, 0.86, 0.1))
		_bottle.visible = false
	elif GameState.day >= ghost_from_day:
		ghost = _seated(ghost_variant)
		UncannyMoves3D.remove_shadow(ghost)
		UncannyMoves3D.ghost_body(ghost)
		# Too close and he turns his face on Rin, then the stool is empty.
		var zone := ProximityZone3D.guard(ghost)
		if zone:
			zone.on_gone = func() -> void:
				ghost.queue_free()
				ghost = null
	talk = NpcTalk3D.new(ut, LINES, REACH)
	talk.turn = false
	talk.head_height = 1.1


func _seated(variant: String) -> PersonRig3D:
	var rig := PersonRig3D.build(self, variant)
	rig.position = SEAT
	rig.rotation.y = -PI * 0.5  # facing the table and the street
	rig.set_seated(true)
	rig.visible = false
	return rig


func _process(_delta: float) -> void:
	var on: bool = host.shift_running
	if ut:
		ut.visible = on
		_bottle.visible = on
	if ghost:
		ghost.visible = on
		if on and not _staring and host.demo_camera:
			_staring = true
			UncannyActor3D.attach(ghost).stare_at(host.demo_camera, 120.0, 0.8)


## E on him: from CHARM_DAY the first line gives Rin the green cord
## "bùa trừ ma da" (ThungCharm3D.FLAG, a loop flag: given again after a reset).
func say() -> String:
	if GameState.day >= CHARM_DAY and not GameState.has_flag(ThungCharm3D.FLAG):
		GameState.set_flag(ThungCharm3D.FLAG)
		LookAtSpeaker3D.person(ut, talk.head_height + 0.1)
		Sfx.play("flip")
		return LINES.named_line("charm")
	return talk.say()


## He is on his stool now.
func seated() -> bool:
	return ut != null and ut.visible


## Rin stands by the shadowless guest (E gets a dead whisper).
func ghost_near(at: Vector3) -> bool:
	return ghost != null and ghost.visible and Vector2(at.x - SEAT.x, at.z - SEAT.z).length() < GHOST_REACH


func ghost_line() -> String:
	return LINES.named_line("ghost").trim_prefix(LINES.speaker + ": ")
