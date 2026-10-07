class_name FishingSpotSpawner
extends Node2D
## Spawns fishing spots at random free positions inside every SeaZone at the
## start of the day (the sea scene is reloaded each day, so spots reset too).
## Re-emits spot signals so listeners don't have to track individual spots.

signal spot_fishable_changed(spot: FishingSpot, can_fish: bool)
signal fishing_requested(spot: FishingSpot)

@export var spot_scene: PackedScene
## Parent node whose SeaZone children define where spots can appear.
@export var zones_root: Node
@export var min_casts: int = 2
@export var max_casts: int = 4
## Radius around a spot that must be free of rocks/land.
@export var clearance: float = 30.0
@export var min_spot_distance: float = 120.0
@export var max_attempts_per_spot: int = 30

@export_group("Catch")
## Picks each spot's featured species.
@export var catalog: FishCatalog
## Map y of the shore (depth 0) and of the far edge (depth 1).
@export var shore_y: float = 1160.0
@export var deep_y: float = 0.0
## How strongly depth favors pricier species (see FishCatalog.pick_random).
@export var rarity_boost: float = 3.0
## Chance a cast brings up the spot's featured species.
@export var featured_chance: float = 0.7
## Chance of a "big shadow" spot, at the shore and at the far edge.
@export var big_chance_shallow: float = 0.05
@export var big_chance_deep: float = 0.4
## Big spots pick their fish as if this deep, with this much extra boost.
@export var big_rarity_boost: float = 8.0
@export var big_max_casts: int = 2

# Tonight's weather (set by WeatherController before spots spawn).
var extra_spots: int = 0
var species_bonus: Dictionary = {}

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	# Physics queries only see static bodies after the first physics frame.
	await get_tree().physics_frame
	spawn_spots()


func spawn_spots() -> void:
	for child in zones_root.get_children():
		var sea_zone := child as SeaZone
		if sea_zone == null or not sea_zone.visible:  # hidden = locked (fog)
			continue
		for i in sea_zone.spot_count + extra_spots:
			var found: bool = false
			for attempt in max_attempts_per_spot:
				var pos := _random_point_in(sea_zone.get_global_rect().grow(-clearance))
				# Skip points covered by another zone drawn on top (fog over open sea).
				if SeaZone.find_at(zones_root, pos) == sea_zone and _is_free(pos):
					_create_spot(pos, sea_zone.zone)
					found = true
					break
			if not found:
				push_warning("No free position for spot in zone %s" % sea_zone.name)


func _random_point_in(rect: Rect2) -> Vector2:
	return Vector2(
		_rng.randf_range(rect.position.x, rect.end.x),
		_rng.randf_range(rect.position.y, rect.end.y))


func _is_free(pos: Vector2) -> bool:
	for spot in get_children():
		if spot.global_position.distance_to(pos) < min_spot_distance:
			return false
	# Keep spots away from places on the map (both use `interact`).
	for poi: Node2D in get_tree().get_nodes_in_group("pois"):
		if poi.global_position.distance_to(pos) < min_spot_distance:
			return false
	var shape := CircleShape2D.new()
	shape.radius = clearance
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, pos)
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


func _create_spot(pos: Vector2, zone: FishData.Zone) -> void:
	var spot: FishingSpot = spot_scene.instantiate()
	spot.global_position = pos
	spot.zone = zone
	spot.casts_left = _rng.randi_range(min_casts, max_casts)
	_roll_catch(spot)
	spot.fishable_changed.connect(spot_fishable_changed.emit)
	spot.fishing_requested.connect(fishing_requested.emit)
	add_child(spot)


## Depth, featured species and big-shadow flag. Further out = better fish
## and more big shadows.
func _roll_catch(spot: FishingSpot) -> void:
	spot.depth = CatchRoll.depth_at(spot.global_position.y, shore_y, deep_y)
	spot.rarity_boost = rarity_boost
	spot.featured_chance = featured_chance
	spot.species_bonus = species_bonus
	if catalog == null:
		return
	var rod := FishData.CatchMethod.ROD
	spot.big_shadow = _rng.randf() < lerpf(big_chance_shallow, big_chance_deep, spot.depth)
	if spot.big_shadow:
		spot.featured = catalog.pick_random(spot.zone, _rng, rod, 1.0, big_rarity_boost, species_bonus)
		spot.casts_left = mini(spot.casts_left, big_max_casts)
	else:
		spot.featured = catalog.pick_random(spot.zone, _rng, rod, spot.depth, rarity_boost, species_bonus)
