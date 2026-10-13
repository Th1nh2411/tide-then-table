class_name WaveMark
extends RefCounted
## "Nhịp Sóng": the mark the creatures from the fog leave on Rin's hand.
## End of night 3 (trip-end cutscene `wave_faint`): back at the dock, Rin
## sees a glowing mackerel in the water, tries one more cast, it bites his
## hand and swims off, he passes out (Bảo finds him); the restaurant's
## `wave_awaken` (running in the rain) gives the power. Separate from the
## real, rare glowing mackerel far out (which still brings the omen). With it Rin can slow the world for a moment
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

## The night of the bite (wave_faint's min_day).
const BITE_FROM_DAY := 3
## The restaurant's rush hour starts from this day (day 2 stays gentle).
const RUSH_FROM_DAY := 3

const BASE_CHARGES := 2
const MAX_CHARGES := 4
## One more use per this many aberrant fish caught.
const ABERRANT_PER_CHARGE := 3
## Fight zone scale for big / aberrant fish once Rin has the power (< 1 = harder).
const HARD_FIGHT_SCALE := 0.8


static func has_power() -> bool:
	return GameState.has_flag(FLAG)


## Rin hasn't been bitten / marked yet.
static func bite_due() -> bool:
	return not has_power() and not GameState.has_flag(BITTEN_FLAG) and not GameState.has_flag(FAINTED_FLAG)



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
