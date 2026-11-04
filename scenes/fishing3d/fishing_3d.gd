class_name Fishing3D
extends Node3D
## First-person rod fishing from the thúng (horror build). Left click (the
## "cast" action) throws the line where Rin looks; the bobber waits, a bite
## shows a "!" for a moment: click to hook (too late = gone, wait again;
## clicking before the bite reels in). Then hold to reel (ReelLogic: tension,
## runs, snap). A landed fish is held in front of the view until Rin looks
## at the basket (FishBasket3D) and presses E. Rod3D draws it all.
## tick() is the whole frame step, so bots and tests can drive it. The bite,
## hook and fight live in BiteReel3D.

signal fish_landed(fish: FishData, size: float)
signal fish_lost(snapped: bool)
signal fish_dropped(count: int)

enum State { IDLE, CASTING, WAITING, BITE, REELING, HOLDING }

const NODE_NAME := "Fishing"
const WATER_Y := 0.12
## Looking at the basket: within this distance of the eye and this cone.
const LOOK_REACH := 2.6
const LOOK_DOT := 0.9

@export var tuning: ReelTuning = ReelTuning.new()

var sea: SeaScene3D
var rod: Rod3D
var basket: FishBasket3D
var state := State.IDLE
var reel: ReelLogic
var fish: FishData
var size := 1.0
var target := Vector3.ZERO
## Bots / tests hold the reel through this (same as holding the button).
var hold_override := false
var _from := Vector3.ZERO
var wait_left := 0.0
var clock := 0.0
var shoal: SeaShoals3D.Shoal
var _text: OnScreenText
var bar: ReelBar
var reel_tick := 0.0


static func attach(host: SeaScene3D) -> Fishing3D:
	var fishing := Fishing3D.new()
	fishing.name = NODE_NAME
	fishing.sea = host
	host.add_child(fishing)
	return fishing


func _ready() -> void:
	rod = Rod3D.new()
	add_child(rod)
	basket = FishBasket3D.new()
	sea.boat_visual.add_child(basket)
	basket.position = FishBasket3D.IN_BOAT
	_text = OnScreenText.new()
	add_child(_text)
	bar = ReelBar.new()
	add_child(bar)


func _exit_tree() -> void:
	Sfx.hold("strain", false)


func line_out() -> bool:
	return state in [State.CASTING, State.WAITING, State.BITE, State.REELING]


func _process(delta: float) -> void:
	if sea.ending:
		_text.prompt("")
		return
	tick(delta)
	_text.prompt("bỏ vào giỏ" if basket_prompt() else "")


func _unhandled_input(event: InputEvent) -> void:
	if sea.ending:
		return
	if event.is_action_pressed("cast"):
		get_viewport().set_input_as_handled()
		press()
		return
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.physical_keycode == KEY_E \
			and state == State.HOLDING and looking_at_basket():
		get_viewport().set_input_as_handled()
		drop_in_basket()


## What a click does in each state.
func press() -> void:
	match state:
		State.IDLE:
			cast()
		State.CASTING, State.WAITING:
			reel_in()
		State.BITE:
			hook()


## One frame of the rod: the cast flight, waiting, the bite window, the reel.
func tick(delta: float) -> void:
	clock += delta
	match state:
		State.CASTING:
			wait_left += delta / maxf(tuning.cast_seconds, 0.01)
			var t := minf(wait_left, 1.0)
			var p := _from.lerp(target, t)
			p.y += sin(t * PI) * tuning.cast_arc
			rod.place_bobber(p)
			if t >= 1.0:
				_landed()
		State.WAITING:
			rod.place_bobber(target + Vector3(0, sin(clock * 3.0) * 0.03, 0))
			if sea._movement_controls_held():
				reel_in()
				return
			wait_left -= delta
			if wait_left <= 0.0:
				BiteReel3D.bite(self)
		State.BITE:
			rod.place_bobber(target + Vector3(0, -0.1 + sin(clock * 30.0) * 0.04, 0))
			rod.shake = maxf(rod.shake, 0.6)
			wait_left -= delta
			if wait_left <= 0.0:
				BiteReel3D.missed(self)
		State.REELING:
			BiteReel3D.reel(self, delta)
	sea.fishing = line_out()


## Throws the line where Rin looks (or at `at`, clamped the same way).
func cast(at: Vector3 = Vector3.INF) -> bool:
	if state != State.IDLE or sea.ending:
		return false
	target = FishingSpot3D.clamp_to_water(sea, at) if at.is_finite() else aim()
	_from = rod.tip_position()
	wait_left = 0.0
	state = State.CASTING
	sea.fishing = true
	Sfx.play("flip")
	return true


func reel_in() -> void:
	if state in [State.CASTING, State.WAITING, State.BITE]:
		rod.reel_in()
		state = State.IDLE
		sea.fishing = false
		Sfx.play("reel")


## Bots / tests: the fish bites now.
func force_bite() -> void:
	if state == State.WAITING:
		BiteReel3D.bite(self)


## A click inside the bite window: the fight starts (BiteReel3D).
func hook() -> bool:
	return BiteReel3D.hook(self)


## Puts the fish in hand into the basket.
func drop_in_basket() -> bool:
	if state != State.HOLDING:
		return false
	basket.add(fish, size)
	rod.hide_fish()
	fish = null
	state = State.IDLE
	Sfx.play("flop")
	sea._update_hud()
	fish_dropped.emit(basket.count())
	return true


## A landed fish in hand and the basket in view (E drops it in).
func basket_prompt() -> bool:
	return state == State.HOLDING and looking_at_basket()


func looking_at_basket() -> bool:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return false
	var to := basket.mouth() - camera.global_position
	return to.length() < LOOK_REACH and (-camera.global_basis.z).dot(to.normalized()) > LOOK_DOT


func _landed() -> void:
	state = State.WAITING
	Sfx.play("splash")
	shoal = FishingSpot3D.shoal_at(sea, target, tuning.shoal_radius)
	wait_left = BiteReel3D.next_bite(self)


## Where a click would throw the line now.
func aim() -> Vector3:
	return FishingSpot3D.aim(sea, tuning, get_viewport().get_camera_3d())
