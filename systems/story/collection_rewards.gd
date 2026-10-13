class_name CollectionRewards
extends RefCounted
## Collecting pays (like DREDGE's encyclopedia / Dave's Marinca): a species
## new to the Dex, every few species (milestones) and a new size record on a
## big catch each give money, announced by NEO. Milestones are paid once
## (story flag "dex_reward_<n>"). Aberrant fish never count. Pure logic.

const FISH_CATALOG_PATH := "res://data/fish/fish_catalog.tres"
## New species: its base price × this, clamped.
const NEW_SPECIES_SCALE := 2
const NEW_SPECIES_MIN := 40
const NEW_SPECIES_MAX := 200
## Species count -> reward (k). The last one is "all regular species".
const MILESTONES := {3: 100, 6: 300}
const RECORD_REWARD := 50
const FLAG_PREFIX := "dex_reward_"


## Pays what this catch earned; returns NEO's lines (empty = nothing).
## Call after GameState.record_catch, with what was true before it.
static func claim(fish: FishData, size: float, was_new: bool, previous_best: float) -> PackedStringArray:
	var lines := PackedStringArray()
	if fish.is_aberrant:
		return lines
	if was_new:
		var money := clampi(fish.base_price * NEW_SPECIES_SCALE, NEW_SPECIES_MIN, NEW_SPECIES_MAX)
		GameState.add_money(money)
		lines.append("NEO: Dex ghi nhận loài mới: %s. Thưởng sưu tầm +%dk." % [fish.display_name, money])
		var count := species_count()
		if MILESTONES.has(count) and not GameState.has_flag(FLAG_PREFIX + str(count)):
			GameState.set_flag(FLAG_PREFIX + str(count))
			GameState.add_money(MILESTONES[count])
			lines.append("NEO: Mốc %d loài! Thưởng thêm +%dk." % [count, MILESTONES[count]])
	elif previous_best > 0.0 and size > previous_best + 0.001 and CatchRoll.is_big(size):
		GameState.add_money(RECORD_REWARD)
		lines.append("NEO: Kỷ lục mới: %s %s! +%dk." % [fish.display_name, fish.weight_text(size), RECORD_REWARD])
	return lines


## Regular (non-aberrant) species caught at least once.
static func species_count() -> int:
	var catalog: FishCatalog = load(FISH_CATALOG_PATH)
	var count := 0
	for fish in catalog.fish:
		if not fish.is_aberrant and int(GameState.caught_species.get(fish.id, 0)) > 0:
			count += 1
	return count


## Phone Dex line: the next milestone still to reach ("" when all paid).
static func next_milestone_text() -> String:
	var count := species_count()
	var keys := MILESTONES.keys()
	keys.sort()
	for target: int in keys:
		if count < target:
			return "Thưởng mốc kế: %d loài +%dk (còn %d)" % [target, MILESTONES[target], target - count]
	return "Đã nhận hết thưởng mốc sưu tầm."
