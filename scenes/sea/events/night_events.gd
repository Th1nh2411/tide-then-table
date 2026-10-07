class_name NightEvents
extends Node2D
## Spawns 1-2 random events each night (not on night 1) at free spots inside
## the boat's range: a stranded boat to tow home, a message bottle, a glowing
## jellyfish swarm, a pod of dolphins leading to good fishing. Pays the tow
## reward when the trip ends at the dock (notes go to the rest screen).

enum Kind { STRANDED, BOTTLE, JELLYFISH, DOLPHINS }

@export var boat: Boat
@export var hud: SeaHud
@export var dialog: PoiDialog
@export var hull: HullController
@export var boat_range: BoatRange
@export var spawner: FishingSpotSpawner
@export var dock: Dock
@export var events_per_night: Vector2i = Vector2i(1, 2)
## Relative chance per Kind.
@export var kind_weights: Array[float] = [1.0, 1.2, 1.0, 1.0]
## Area events can appear in, and how far from the dock / other things.
@export var area: Rect2 = Rect2(60, 60, 1800, 1000)
@export var min_dock_distance: float = 250.0
@export var min_spacing: float = 120.0
@export var clearance: float = 40.0
@export var owner_names: Array[String] = ["Chú Sáu", "Bác Hai", "Anh Tư", "Cô Ba"]

var _rng := RandomNumberGenerator.new()
var _stranded: Array[StrandedBoat] = []


func _ready() -> void:
	_rng.randomize()
	if GameState.day <= 1:
		return  # keep night 1 for learning the basics
	# Wait for the spawner (it places spots after the first physics frame).
	await get_tree().physics_frame
	await get_tree().physics_frame
	var count := _rng.randi_range(events_per_night.x, events_per_night.y)
	for kind in pick_kinds(_rng, count, kind_weights):
		var pos := _find_free_point()
		if pos != Vector2.INF:
			_spawn(kind, pos)


## `count` different kinds, weighted.
static func pick_kinds(rng: RandomNumberGenerator, count: int, weights: Array[float]) -> Array[int]:
	var left := PackedFloat32Array(weights)
	var kinds: Array[int] = []
	for i in mini(count, weights.size()):
		var kind := rng.rand_weighted(left)
		kinds.append(kind)
		left[kind] = 0.0
	return kinds


## Called by the sea scene when the trip ends. Pays tows if Rin docked.
func on_trip_end(rescued: bool) -> void:
	for stranded in _stranded:
		if not is_instance_valid(stranded) or not stranded.towing:
			continue
		if rescued:
			GameState.trip_notes.append("%s được cứu hộ kéo về luôn, không gửi tiền." % stranded.owner_name)
		else:
			GameState.add_money(stranded.reward)
			GameState.trip_notes.append("Kéo ghe %s về bến: +%dk" % [stranded.owner_name, stranded.reward])


func _spawn(kind: int, pos: Vector2) -> void:
	match kind:
		Kind.STRANDED:
			var stranded := StrandedBoat.new()
			stranded.boat = boat
			stranded.owner_name = owner_names[_rng.randi() % owner_names.size()]
			stranded.title = "Ghe %s chết máy" % stranded.owner_name
			stranded.prompt_text = "E: Hỏi"
			stranded.reach = 35.0
			stranded.lamp_radius = 55.0
			_add_place(stranded, pos)
			_stranded.append(stranded)
		Kind.BOTTLE:
			var bottle := MessageBottle.new()
			bottle.title = "Chai thư"
			bottle.prompt_text = "E: Vớt"
			bottle.reach = 25.0
			bottle.lamp_color = Color(0.6, 1.0, 0.7)
			bottle.lamp_radius = 30.0
			bottle.label_offset = Vector2(0, -12)
			_add_place(bottle, pos)
		Kind.JELLYFISH:
			var jellyfish := JellyfishBloom.new()
			jellyfish.hull = hull
			jellyfish.hud = hud
			jellyfish.position = pos
			add_child(jellyfish)
		Kind.DOLPHINS:
			var dolphins := DolphinPod.new()
			dolphins.boat = boat
			dolphins.hud = hud
			dolphins.spawner = spawner
			dolphins.min_y = boat_range.limit_y if is_finite(boat_range.limit_y) else -INF
			dolphins.position = pos
			add_child(dolphins)


func _add_place(place: PointOfInterest, pos: Vector2) -> void:
	place.hud = hud
	place.dialog = dialog
	place.position = pos
	add_child(place)


## Random free water inside the boat's range, or Vector2.INF if none found.
func _find_free_point() -> Vector2:
	var top := area.position.y
	if is_finite(boat_range.limit_y):
		top = maxf(top, boat_range.limit_y + clearance)
	for attempt in 40:
		var pos := Vector2(_rng.randf_range(area.position.x, area.end.x), _rng.randf_range(top, area.end.y))
		if pos.distance_to(dock.global_position) >= min_dock_distance and _is_free(pos):
			return pos
	return Vector2.INF


func _is_free(pos: Vector2) -> bool:
	var others: Array[Node] = get_children()
	others.append_array(get_tree().get_nodes_in_group("pois"))
	others.append_array(spawner.get_children())
	for other in others:
		if (other as Node2D).global_position.distance_to(pos) < min_spacing:
			return false
	var shape := CircleShape2D.new()
	shape.radius = clearance
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, pos)
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()
