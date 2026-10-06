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

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	# Physics queries only see static bodies after the first physics frame.
	await get_tree().physics_frame
	spawn_spots()


func spawn_spots() -> void:
	for child in zones_root.get_children():
		var sea_zone := child as SeaZone
		if sea_zone == null:
			continue
		for i in sea_zone.spot_count:
			var found: bool = false
			for attempt in max_attempts_per_spot:
				var pos := _random_point_in(sea_zone.get_global_rect().grow(-clearance))
				if _is_free(pos):
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
	spot.fishable_changed.connect(spot_fishable_changed.emit)
	spot.fishing_requested.connect(fishing_requested.emit)
	add_child(spot)
