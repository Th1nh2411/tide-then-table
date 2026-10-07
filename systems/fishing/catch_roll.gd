class_name CatchRoll
extends RefCounted
## Pure helpers for what a rod cast brings up: how "deep" a point of the map
## is (0 at the shore, 1 at the far edge) and how big the hooked fish is.
## Size 1.0 = average; it scales price, weight and fight difficulty.

const MIN_SIZE: float = 0.6
const MAX_SIZE: float = 1.8
## At or above this size the catch is called "to" (big) in messages.
const BIG_SIZE: float = 1.3


## 0..1 by map y: `shore_y` (dock side) -> 0, `deep_y` (far out) -> 1.
static func depth_at(y: float, shore_y: float, deep_y: float) -> float:
	return clampf(inverse_lerp(shore_y, deep_y, y), 0.0, 1.0)


## Random size around 1.0, shifted up by depth and by a "big shadow" spot.
static func roll_size(rng: RandomNumberGenerator, depth: float, big_spot: bool,
		spread: float = 0.15, depth_bonus: float = 0.25, big_bonus: float = 0.35) -> float:
	var mean := 1.0 + depth * depth_bonus + (big_bonus if big_spot else 0.0)
	return clampf(rng.randfn(mean, spread), MIN_SIZE, MAX_SIZE)


## Fight difficulty multiplier for minigames' zone_scale (> 1 = easier):
## a 1.5x fish with `weight` 0.3 makes the game ~13% harder.
static func size_zone_scale(size: float, weight: float = 0.3) -> float:
	return 1.0 / (1.0 + (size - 1.0) * weight)


static func is_big(size: float) -> bool:
	return size >= BIG_SIZE
