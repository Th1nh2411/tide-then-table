class_name DolphinPod
extends Node2D
## Night event: a pod of dolphins with a glowing wake. When the boat comes
## close they swim off toward the best fishing spot (a big shadow if there is
## one) and wait there; follow them to find it. They leave after a while.

@export var boat: Boat
@export var hud: SeaHud
@export var spawner: FishingSpotSpawner
## Only lead to spots south of this y (inside the boat's range).
@export var min_y: float = -INF
@export var notice_distance: float = 140.0
@export var swim_speed: float = 55.0
@export var stay_seconds: float = 25.0
@export var color: Color = Color(0.75, 0.85, 0.95)
@export var glow: float = 3.0

var _target: Node2D
var _noticed: bool = false
var _arrived_time: float = -1.0
var _time: float = 0.0


func _ready() -> void:
	add_child(PointOfInterest.make_lamp(Color(0.6, 0.9, 1.0), 55.0, 0.6))


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	if not _noticed:
		if is_instance_valid(boat) and boat.global_position.distance_to(global_position) < notice_distance:
			_noticed = true
			_target = best_spot(spawner.get_children(), min_y)
			hud.flash_message("Đàn cá heo! Đi theo tụi nó thử xem.", 2.0)
		return
	if is_instance_valid(_target) and _arrived_time < 0.0:
		global_position = global_position.move_toward(_target.global_position, swim_speed * delta)
		if global_position.distance_to(_target.global_position) < 20.0:
			_arrived_time = _time
	elif _arrived_time < 0.0:
		_arrived_time = _time  # spot gone: just linger
	elif _time - _arrived_time > stay_seconds:
		modulate.a -= delta * 0.5
		if modulate.a <= 0.0:
			queue_free()


## Big-shadow spot first, else the one with the priciest featured fish.
static func best_spot(spots: Array, limit_y: float) -> FishingSpot:
	var best: FishingSpot = null
	var best_score := -1.0
	for node in spots:
		var spot := node as FishingSpot
		if spot == null or spot.featured == null or spot.global_position.y < limit_y:
			continue
		var score := float(spot.featured.base_price) + (1000.0 if spot.big_shadow else 0.0)
		if score > best_score:
			best_score = score
			best = spot
	return best


func _draw() -> void:
	var bright := Color(color.r * glow, color.g * glow, color.b * glow, 0.9)
	for i in 3:
		var offset := Vector2(i * 9.0 - 9.0, sin(_time * 3.0 + i * 1.3) * 4.0)
		var jump := maxf(sin(_time * 2.5 + i * 2.0), 0.0) * 3.0
		draw_arc(offset, 4.0 + jump, PI * 1.1, PI * 1.9, 6, bright, 1.5)
		draw_circle(offset + Vector2(-4, 1), 1.0, Color(bright, 0.4))
