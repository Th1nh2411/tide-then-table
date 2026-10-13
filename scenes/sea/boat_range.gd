class_name BoatRange
extends Node2D
## Rough water past what the current boat can handle (BoatData.max_depth,
## Dredge style): crossing the foam line gets the boat shoved back and slowed.
## Bigger boats push the line further out, so boat upgrades open the map.
## The foam is drawn with an over-bright color so it still shows through the
## dark night tint.

signal limit_changed(limit_y: float)

@export var boat: Boat
@export var hud: SeaHud
## Same depth scale as the spawner: shore_y = depth 0, deep_y = depth 1.
@export var shore_y: float = 1160.0
@export var deep_y: float = 0.0
@export var map_width: float = 1920.0
## How fast the waves push the boat back (px/s), and the speed cap meanwhile.
@export var push_speed: float = 90.0
@export var max_speed_in_waves: float = 20.0
@export var message_cooldown: float = 4.0
@export var foam_color: Color = Color(0.85, 0.95, 1.0, 0.8)
## Multiplier so the foam survives the night CanvasModulate (~0.15).
@export var foam_glow: float = 4.0

var limit_y: float = -INF
var _message_left: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	boat.boat_data_changed.connect(_on_boat_data_changed)
	if boat.boat_data:
		_on_boat_data_changed(boat.boat_data)


## Map y the boat may not go above (north of) for this boat type.
func limit_for(data: BoatData) -> float:
	if data.max_depth >= 1.0:
		return -INF
	return lerpf(shore_y, deep_y, data.max_depth)


func _on_boat_data_changed(data: BoatData) -> void:
	limit_y = limit_for(data)
	limit_changed.emit(limit_y)
	queue_redraw()


func _physics_process(delta: float) -> void:
	_message_left -= delta
	if not boat.is_physics_processing() or boat.global_position.y >= limit_y:
		return
	boat.global_position.y = minf(boat.global_position.y + push_speed * delta, limit_y)
	boat.speed = clampf(boat.speed, -max_speed_in_waves, max_speed_in_waves)
	if _message_left <= 0.0:
		_message_left = message_cooldown
		hud.flash_message("Sóng to quá... %s chỉ ra tới đây thôi. Phải nâng cấp thuyền mới đi xa hơn được." % boat.boat_data.display_name, 2.5)


func _process(delta: float) -> void:
	if is_finite(limit_y):
		_time += delta
		queue_redraw()


func _draw() -> void:
	if not is_finite(limit_y):
		return
	var color := Color(foam_color.r * foam_glow, foam_color.g * foam_glow, foam_color.b * foam_glow, foam_color.a)
	# A row of small breaking-wave arcs drifting sideways.
	var step := 24.0
	var x := fmod(_time * 10.0, step) - step
	while x < map_width:
		var y := limit_y + sin(x * 0.05 + _time * 2.0) * 3.0
		draw_arc(Vector2(x, y), 6.0, PI, TAU, 6, color, 1.5)
		x += step
