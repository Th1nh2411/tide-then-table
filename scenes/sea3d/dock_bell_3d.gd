class_name DockBell3D
extends Node3D
## A small bell hung at the pier head with a few chimes: it rings every few
## seconds (positional, Sfx.play_at), heard within RANGE, so a thúng lost in
## the dark can find home by ear. Silent when headless (Sfx); `rings` counts.

## Heard within this many metres (the player's max distance).
const RANGE := 42.0
## Seconds between rings, plus up to JITTER more.
const EVERY := 4.5
const JITTER := 2.0
## Every n-th ring is the wind chime instead of the bell.
const CHIME_EVERY := 3

var listener: Node3D
var rings := 0
var _wait := 1.0
var _rng := RandomNumberGenerator.new()


static func attach(host: Node3D, at: Vector3) -> DockBell3D:
	var bell := DockBell3D.new()
	bell.name = "DockBell"
	host.add_child(bell)
	bell.position = at
	bell.listener = host.get("boat") as Node3D
	return bell


func _ready() -> void:
	_rng.seed = 4242
	_wait = _rng.randf_range(0.5, 1.5)


func _process(delta: float) -> void:
	_wait -= delta
	if _wait > 0.0:
		return
	_wait = EVERY + _rng.randf() * JITTER
	if listener and listener.global_position.distance_to(global_position) > RANGE:
		return
	rings += 1
	var sound := "wind_chime" if rings % CHIME_EVERY == 0 else "dock_bell"
	Sfx.play_at(sound, global_position, self, _rng.randf_range(0.96, 1.04), 7.0, RANGE)
