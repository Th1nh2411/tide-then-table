class_name EndingStats
extends RefCounted
## The short "how did your run go" card on the ending screen: days and
## minutes played, fish caught, guests served and money earned. Pure logic.


## Three short lines, e.g. "5 ngày · 44 phút".
static func lines(species_total: int) -> PackedStringArray:
	var fish := 0
	for id: Variant in GameState.caught_species:
		fish += int(GameState.caught_species[id])
	var served := 0
	var earned := 0
	for record: Dictionary in GameState.day_history:
		served += int(record.get("served", 0))
		earned += int(record.get("earned", 0))
	return PackedStringArray([
		"%d ngày · %d phút" % [GameState.day, roundi(GameState.play_seconds / 60.0)],
		"%d con cá · %d/%d loài" % [fish, GameState.caught_species.size(), species_total],
		"%d bàn khách · thu %dk" % [served, earned],
	])


## The same numbers for the newspaper clipping: days, minutes, fish,
## species, species_total, served, earned (k).
static func values(species_total: int) -> Dictionary:
	var fish := 0
	for id: Variant in GameState.caught_species:
		fish += int(GameState.caught_species[id])
	var served := 0
	var earned := 0
	for record: Dictionary in GameState.day_history:
		served += int(record.get("served", 0))
		earned += int(record.get("earned", 0))
	return {"days": GameState.day, "minutes": roundi(GameState.play_seconds / 60.0), "fish": fish,
		"species": GameState.caught_species.size(), "species_total": species_total,
		"served": served, "earned": earned}
