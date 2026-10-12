class_name BoatCondition
extends RefCounted
## Hull condition of the player's boat (GameState.boat_hp, 0..MAX_HP) and
## repair pricing. The boat is "broken" at 0 HP and can't sail until repaired.

const MAX_HP: float = 100.0


static func is_damaged() -> bool:
	return GameState.boat_hp < MAX_HP


static func is_broken() -> bool:
	return GameState.boat_hp <= 0.0


static func damage(amount: float) -> void:
	GameState.boat_hp = clampf(GameState.boat_hp - amount, 0.0, MAX_HP)


## The rescue crew's free patch after towing a broken boat home, so a
## player with no money can still sail (no softlock).
static func tow_patch(min_hp: float) -> void:
	GameState.boat_hp = clampf(maxf(GameState.boat_hp, min_hp), 0.0, MAX_HP)


## Price to bring the hull back to full with this boat's repair rate.
static func full_repair_cost(boat: BoatData) -> int:
	return ceili((MAX_HP - GameState.boat_hp) * boat.repair_cost_per_hp)


## Repairs as much as the player can afford. Returns the money spent.
static func repair(boat: BoatData) -> int:
	if boat.repair_cost_per_hp <= 0:
		GameState.boat_hp = MAX_HP
		return 0
	var missing := MAX_HP - GameState.boat_hp
	var affordable := minf(missing, floorf(GameState.money / boat.repair_cost_per_hp))
	var cost := ceili(affordable * boat.repair_cost_per_hp)
	if affordable <= 0.0 or not GameState.spend_money(cost):
		return 0
	GameState.boat_hp = minf(GameState.boat_hp + affordable, MAX_HP)
	return cost
