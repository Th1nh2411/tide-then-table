class_name WaveMark
extends RefCounted
## "Nhịp Sóng": the mark the creatures from the fog leave on Rin's hand (on
## the omen night: bitten by the glowing mackerel while fishing, or touched
## by the glow in the fog). With it Rin can slow the world for a moment
## (WavePower, key C) a few times a night at sea and a few times a shift in
## the restaurant. Once he has it, some moments get harder so it's worth
## using: big / aberrant fish fight harder, pricey grill dishes are trickier,
## and the restaurant has a rush hour. Pure logic, no nodes.

## Set when Rin has the power (the wave_awaken cutscene).
const FLAG := "wave_mark"
## Set when the glowing mackerel bit him while fishing (he passes out at sea).
const BITTEN_FLAG := "wave_bitten"
## Set when he passed out (at sea or on the dock); the restaurant's
## wave_awaken cutscene (running in the rain) then gives the power.
const FAINTED_FLAG := "wave_fainted"
const FISH_CATALOG_PATH := "res://data/fish/fish_catalog.tres"

const BASE_CHARGES := 2
const MAX_CHARGES := 4
## One more use per this many aberrant fish caught.
const ABERRANT_PER_CHARGE := 3
## Fight zone scale for big / aberrant fish once Rin has the power (< 1 = harder).
const HARD_FIGHT_SCALE := 0.8


static func has_power() -> bool:
	return GameState.has_flag(FLAG)


## Uses per night (sea) or per shift (restaurant).
static func max_charges() -> int:
	return mini(BASE_CHARGES + aberrant_caught() / ABERRANT_PER_CHARGE, MAX_CHARGES)


static func aberrant_caught() -> int:
	var catalog: FishCatalog = load(FISH_CATALOG_PATH)
	var total := 0
	for fish in catalog.fish:
		if fish.is_aberrant:
			total += int(GameState.caught_species.get(fish.id, 0))
	return total


## Extra difficulty for a fight (multiplies the zone scale).
static func fight_scale(fish: FishData, big: bool) -> float:
	return HARD_FIGHT_SCALE if has_power() and (big or fish.is_aberrant) else 1.0
