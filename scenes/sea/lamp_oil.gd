class_name LampOil
extends Node
## Lamp oil for night fishing: the limit of a sea trip, like the oxygen tank
## in Dave the Diver. Burns over real time (not during minigames, not at the
## dock, not while paused) and a little per action (cast, net). It also drives the
## displayed time: full tank = midnight, empty = dawn. Running dry at sea
## means a rescue tow (handled by the sea scene). The tank refills for free
## every night; the "lamp" upgrade makes the tank bigger.

signal oil_changed(amount: float, capacity: float)
signal oil_low
signal oil_empty

## Lamp tank upgrade: its value is the tank capacity. Without it: base_capacity.
@export var lamp_upgrade: UpgradeData
## Tank size without the upgrade; 100 lasts about 240 real seconds of sailing.
@export var base_capacity: float = 100.0
## No burning while a minigame is running (time stops while fishing).
@export var minigame: FishingMinigame
## No burning while the boat is at the dock.
@export var dock: Dock
## Base tank (100) lasts ~240 real seconds of sailing.
@export var burn_per_second: float = 100.0 / 240.0
## 0 = time frozen during minigames.
@export var minigame_burn_scale: float = 0.0
## Warn once when the tank drops to this fraction.
@export var low_fraction: float = 0.25

var capacity: float = 100.0
var amount: float = 100.0

var _low_sent: bool = false
var _empty_sent: bool = false


func _ready() -> void:
	capacity = float(GameState.get_upgrade_value(lamp_upgrade)) if lamp_upgrade else base_capacity
	amount = capacity  # free refill every night
	_apply.call_deferred()


func fraction() -> float:
	return amount / capacity


func is_empty() -> bool:
	return amount <= 0.0


## Oil spent by an action (casting, dropping or hauling a net).
func spend(units: float) -> void:
	amount = maxf(amount - units, 0.0)
	_apply()


func _process(delta: float) -> void:
	if not DayClock.running or is_empty():
		return
	if dock and dock.is_boat_inside():
		return
	var scale := minigame_burn_scale if minigame and minigame.is_running() else 1.0
	amount = maxf(amount - burn_per_second * scale * delta, 0.0)
	_apply()


func _apply() -> void:
	if DayClock.running:
		DayClock.set_progress(1.0 - fraction(), DayClock.night_start_hour, DayClock.dawn_hour)
	oil_changed.emit(amount, capacity)
	if not _low_sent and fraction() <= low_fraction:
		_low_sent = true
		oil_low.emit()
	if not _empty_sent and is_empty():
		_empty_sent = true
		oil_empty.emit()
