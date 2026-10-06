class_name FogArea
extends Node2D
## The fog at the map edge: drifting fog overlay + glowing whirlpool. Only
## present once Story.is_fog_open(); also toggles the FOG SeaZone so the
## spawner places aberrant-fish spots there.

signal whirlpool_entered(whirlpool: Whirlpool)

## FOG water zone (child of the Zones node, so spots spawn there).
@export var fog_zone: SeaZone
@export var fog_color: Color = Color(0.92, 0.95, 1.0, 0.18)
@export var blob_count: int = 14
@export var drift_speed: float = 0.3

var _time: float = 0.0
var _blobs: Array[Vector3] = []  # x, y, radius (inside the fog rect)

@onready var _whirlpool: Whirlpool = $Whirlpool


func _ready() -> void:
	var open := Story.is_fog_open()
	visible = open
	fog_zone.visible = open
	_whirlpool.monitoring = open
	_whirlpool.boat_entered.connect(func(_boat: Boat) -> void: whirlpool_entered.emit(_whirlpool))
	var rect := fog_zone.get_global_rect()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7  # same fog shape every day
	for i in blob_count:
		_blobs.append(Vector3(
			rng.randf_range(rect.position.x, rect.end.x),
			rng.randf_range(rect.position.y, rect.end.y),
			rng.randf_range(50, 110)))


func get_whirlpool_position() -> Vector2:
	return _whirlpool.global_position


func _process(delta: float) -> void:
	if visible:
		_time += delta
		queue_redraw()


func _draw() -> void:
	# Overlapping translucent circles that drift slowly read as fog.
	for i in _blobs.size():
		var blob := _blobs[i]
		var offset := Vector2(sin(_time * drift_speed + i), cos(_time * drift_speed * 0.7 + i * 2.0)) * 20.0
		draw_circle(to_local(Vector2(blob.x, blob.y) + offset), blob.z, fog_color)
