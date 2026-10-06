class_name NetBuoy
extends Area2D
## Float marking a net the player dropped. Shellfish collect in the net over
## in-game time (the ring around the buoy fills up). When the boat is next to
## it and slow, `interact` asks to haul it.

signal haulable_changed(buoy: NetBuoy, can_haul: bool)
signal haul_requested(buoy: NetBuoy)

## Boat must be slower than this (px/s) to haul.
@export var max_haul_speed: float = 15.0
@export var buoy_color: Color = Color(1.0, 0.5, 0.15)
@export var ring_color: Color = Color(1, 1, 1, 0.8)

## Set by NetController before the buoy enters the tree.
var fish: FishData
var drop_minutes: float = 0.0
## Soak time (in-game minutes) for a full net; drives the progress ring.
var full_minutes: float = 180.0

var _boat: Boat
var _can_haul: bool = false
var _time: float = 0.0


func _ready() -> void:
	add_to_group("net_buoys")  # for the off-screen markers
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func soak_minutes() -> float:
	return maxf(DayClock.current_minutes - drop_minutes, 0.0)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	var can_haul := _boat != null and absf(_boat.speed) <= max_haul_speed
	if can_haul != _can_haul:
		_can_haul = can_haul
		haulable_changed.emit(self, can_haul)


func _unhandled_input(event: InputEvent) -> void:
	if _can_haul and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		haul_requested.emit(self)


func _on_body_entered(body: Node2D) -> void:
	if body is Boat:
		_boat = body


func _on_body_exited(body: Node2D) -> void:
	if body == _boat:
		_boat = null


func _draw() -> void:
	var bob := Vector2(0, sin(_time * 2.5) * 1.5)
	# Progress ring: how full the net is.
	var fill := clampf(soak_minutes() / full_minutes, 0.0, 1.0)
	draw_arc(Vector2.ZERO, 9, 0, TAU, 24, Color(0, 0, 0, 0.3), 2.0)
	if fill > 0.0:
		draw_arc(Vector2.ZERO, 9, -PI / 2, -PI / 2 + TAU * fill, 24, ring_color, 2.0)
	draw_circle(bob, 4, buoy_color)
	draw_line(bob + Vector2(0, -4), bob + Vector2(0, -10), Color.WHITE, 1.0)
