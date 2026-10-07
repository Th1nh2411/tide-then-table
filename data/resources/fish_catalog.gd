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
## `depth` (0 = shore, 1 = far out) × `rarity_boost` raises the weight of
## pricier species: the further out, the better the fish.
## Returns null if nothing matching lives in the zone.
func pick_random(zone: FishData.Zone, rng: RandomNumberGenerator,
		method: FishData.CatchMethod = FishData.CatchMethod.ROD,
		depth: float = 0.0, rarity_boost: float = 0.0) -> FishData:
	var candidates := get_fish_for_zone(zone, method)
	var weights: Array[float] = []
	var max_price := 1
	# Aberrant fish stay rare (story pacing): no depth boost for them.
	for f in candidates:
		if not f.is_aberrant:
			max_price = maxi(max_price, f.base_price)
	var total := 0.0
	for f in candidates:
		var value := 0.0 if f.is_aberrant else float(f.base_price) / max_price
		var w := f.spawn_weight * (1.0 + rarity_boost * depth * value)
		weights.append(w)
		total += w
	if total <= 0.0:
		return null
	var roll := rng.randf() * total
	for i in candidates.size():
		roll -= weights[i]
		if roll < 0.0:
			return candidates[i]
	# Float rounding can leave roll at exactly 0; fall back to the last one.
	return candidates.back()
