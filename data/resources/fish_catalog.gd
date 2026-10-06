class_name FishCatalog
extends Resource
## List of every species in the game, plus weighted random picking by zone.
## Add a new fish by creating its .tres and appending it to fish_catalog.tres.

@export var fish: Array[FishData] = []


func get_fish_for_zone(zone: FishData.Zone,
		method: FishData.CatchMethod = FishData.CatchMethod.ROD) -> Array[FishData]:
	var result: Array[FishData] = []
	for f in fish:
		if f.lives_in(zone) and f.catch_method == method:
			result.append(f)
	return result


## Weighted pick using spawn_weight among species caught with `method`.
## Returns null if nothing matching lives in the zone.
func pick_random(zone: FishData.Zone, rng: RandomNumberGenerator,
		method: FishData.CatchMethod = FishData.CatchMethod.ROD) -> FishData:
	var candidates := get_fish_for_zone(zone, method)
	var total := 0.0
	for f in candidates:
		total += f.spawn_weight
	if total <= 0.0:
		return null
	var roll := rng.randf() * total
	for f in candidates:
		roll -= f.spawn_weight
		if roll < 0.0:
			return f
	# Float rounding can leave roll at exactly 0; fall back to the last one.
	return candidates.back()
