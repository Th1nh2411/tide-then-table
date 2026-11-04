class_name VyStaff3D
extends Node
## Vy, Bảo's old friend, works the shift every day: walks in from the west
## end when the shift opens, then one job at a time (a ready plate from the
## bench to its table, else wiping a dirty table), resting between jobs;
## walks off when the shift is over. Slower than Rin so he still matters.
## A plate she takes is marked `order["staff"]` (Rin skips it). Talk: VyTalk3D.

const L = preload("res://scenes/restaurant3d/restaurant_layout_3d.gd")
const ENTRY := Vector3(-12.0, 0, 5.8)
const HOME := Vector3(-3.0, 0, -3.5)
const BENCH_SPOT := Vector3(-1.75, 0, -3.45)

## Ground speeds (m/s); Rin walks 1.8.
@export var walk_speed: float = 1.15
@export var carry_speed: float = 0.95
## Seconds: picking a plate up, setting it down, wiping a table, rest between jobs.
@export var pickup_seconds: float = 0.8
@export var serve_seconds: float = 0.7
@export var wipe_seconds: float = 2.5
@export var rest_seconds: float = 3.0
## She waits instead of walking into Rin closer than this (m), at most
## `yield_seconds`; next to her goal with Rin on it she just works from there.
@export var personal_space: float = 0.85
@export var yield_seconds: float = 1.2

var host: Node3D
var rig: PersonRig3D
var talk: VyTalk3D
## away, arrive, idle, to_bench, pickup, carry, serve, to_dirty, wipe, leave, gone.
var state := "away"
var table := -1
var wait := 0.0
## This shift's work (the bot prints it).
var served := 0
var wiped := 0
var _target := Vector3.ZERO
var _yielded := 0.0


func setup(owner: Node3D) -> void:
	host = owner
	rig = PersonRig3D.build(host, "vy")
	rig.name = "Vy"
	rig.visible = false
	talk = VyTalk3D.new(self)


func _process(delta: float) -> void:
	if host and not get_tree().paused:
		tick(delta)


func present() -> bool:
	return rig != null and rig.visible


## One step of her day; tests and the bot may call it with big deltas.
func tick(delta: float) -> void:
	if host.shift_over and not state in ["away", "leave", "gone"]:
		_drop()
		_go("leave", ENTRY)
	match state:
		"away":
			if host.shift_running:
				rig.position = ENTRY
				rig.visible = true
				_go("arrive", HOME)
		"idle":
			wait -= 0.0 if talk.holding(delta) else delta
			if wait <= 0.0:
				_pick_job()
		"pickup", "serve", "wipe":
			wait -= delta
			_sway()
			if wait <= 0.0:
				_finish_pause()
		"arrive", "to_bench", "carry", "to_dirty", "leave":
			if state == "carry" and not _still_mine():
				_drop()  # the guests left
				_rest(0.5)
				return
			if talk.holding(delta):
				return
			if _rin_in_way():
				_yielded += delta
				if rig.position.distance_to(_target) < 0.9:
					_yielded = 0.0
					_arrived()
					return
				if _yielded < yield_seconds:
					return
			else:
				_yielded = 0.0
			if _walk(delta):
				_arrived()


func _pick_job() -> void:
	if host.service.staff_pick() >= 0:
		_go("to_bench", BENCH_SPOT)
		return
	var best := -1
	for i in range(host.dirty_tables.size()):
		if host.dirty_tables[i] and (best < 0 or rig.position.distance_to(L.TABLES[i]) < rig.position.distance_to(L.TABLES[best])):
			best = i
	if best >= 0:
		table = best
		_go("to_dirty", _service_point(best))
	else:
		wait = 0.5


func _arrived() -> void:
	match state:
		"arrive":
			_rest(0.5)
		"to_bench":
			table = host.service.staff_pick()
			if table < 0:
				_rest(rest_seconds * 0.5)
				return
			host.orders[table]["staff"] = true
			state = "pickup"
			wait = pickup_seconds
		"carry":
			state = "serve"
			wait = serve_seconds
		"to_dirty":
			if not host.dirty_tables[table]:
				_rest(0.5)  # Rin got there first
				return
			state = "wipe"
			wait = wipe_seconds
		"leave":
			rig.visible = false
			state = "gone" if host.shift_over else "away"


func _finish_pause() -> void:
	match state:
		"pickup":
			if not _still_mine():
				_drop()
				_rest(0.5)
				return
			rig.set_carrying(true)
			ServedFoodVisual3D.show_dish(rig.plate, host.orders[table]["dish"] as DishData)
			_go("carry", _service_point(table))
		"serve":
			if _still_mine():
				host.service.staff_serve(table)
				served += 1
			_drop()
			_rest(rest_seconds)
		"wipe":
			if host.dirty_tables[table]:
				wiped += 1
			host.service.clean_table(table, true)
			_rest(rest_seconds)


func _still_mine() -> bool:
	return table >= 0 and bool(host.orders[table].get("staff", false))


## Lets go of her plate (served, lost, or the shift closed).
func _drop() -> void:
	if table >= 0 and table < host.orders.size() and not host.orders[table].is_empty():
		host.orders[table].erase("staff")
	table = -1
	rig.set_carrying(false)


func _rest(seconds: float) -> void:
	state = "idle"
	wait = seconds
	table = -1


func _go(next: String, where: Vector3) -> void:
	state = next
	_target = where


## True on arrival.
func _walk(delta: float) -> bool:
	var speed := carry_speed if rig.carrying else walk_speed
	StaffPathing3D.move(rig, L.TABLES, _target, speed, delta)
	return rig.position.distance_to(_target) < 0.08


func _rin_in_way() -> bool:
	var rin: Vector3 = host.player.position
	var ahead := _target - rig.position
	var to_rin := rin - rig.position
	return to_rin.length() < personal_space and ahead.dot(to_rin) > 0.0


## Busy at the bench / a table: face it, a small working sway.
func _sway() -> void:
	var at: Vector3 = L.PASS_POSITION if state == "pickup" else L.TABLES[maxi(table, 0)]
	var to := at - rig.position
	rig.rotation.y = lerp_angle(rig.rotation.y, atan2(to.x, to.z), 0.2) + sin(Time.get_ticks_msec() * 0.007) * 0.03


static func _service_point(index: int) -> Vector3:
	return (L.TABLES[index] as Vector3) + L.TABLE_SERVICE_OFFSET
