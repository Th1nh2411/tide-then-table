class_name BoatCondition
extends RefCounted
## Hull condition of the player's boat (GameState.boat_hp, 0..MAX_HP).
## The boat is "broken" at 0 HP; F at the dock repairs it for free.

const MAX_HP: float = 100.0


static func is_damaged() -> bool:
	return GameState.boat_hp < MAX_HP


static func is_broken() -> bool:
	return GameState.boat_hp <= 0.0


static func damage(amount: float) -> void:
	GameState.boat_hp = clampf(GameState.boat_hp - amount, 0.0, MAX_HP)


## The free patch after a broken boat is brought home (no softlock).
static func tow_patch(min_hp: float) -> void:
	GameState.boat_hp = clampf(maxf(GameState.boat_hp, min_hp), 0.0, MAX_HP)


## Repairs the hull to full (free: no money in the horror build).
static func repair() -> void:
	GameState.boat_hp = MAX_HP
