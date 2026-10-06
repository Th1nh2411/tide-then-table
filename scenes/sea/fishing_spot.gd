class_name FishingSpot
extends Area2D
## Bubbling patch of water with a limited number of casts.
## When the boat is inside and slow enough, `interact` requests fishing.
## Disappears once all casts are used; new spots spawn the next day.

signal fishable_changed(spot: FishingSpot, can_fish: bool)
signal fishing_requested(spot: FishingSpot)

## Boat must be slower than this (px/s) to start fishing.
@export var max_fishing_speed: float = 15.0
@export var bubble_color: Color = Color(1, 1, 1, 0.85)
@export var bubble_spread: float = 8.0
@export var blink_speed: float = 4.0

## Set by the spawner before the spot enters the tree.
var zone: FishData.Zone = FishData.Zone.NEARSHORE
var casts_left: int = 3

var _boat: Boat
var _can_fish: bool = false
var _time: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	var can_fish := _boat != null and absf(_boat.speed) <= max_fishing_speed and casts_left > 0
	_set_can_fish(can_fish)


func _unhandled_input(event: InputEvent) -> void:
	if _can_fish and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		fishing_requested.emit(self)


## Consume one cast. The spot removes itself when empty.
func use_cast() -> void:
	casts_left -= 1
	if casts_left <= 0:
		_set_can_fish(false)
		queue_free()


func _set_can_fish(value: bool) -> void:
	if value != _can_fish:
		_can_fish = value
		fishable_changed.emit(self, value)


func _on_body_entered(body: Node2D) -> void:
	if body is Boat:
		_boat = body


func _on_body_exited(body: Node2D) -> void:
	if body == _boat:
		_boat = null


func _draw() -> void:
	# A few bubbles pulsing out of phase reads as "something is down there".
	for i in 5:
		var angle := TAU * i / 5.0 + _time * 0.5
		var pulse := 0.5 + 0.5 * sin(_time * blink_speed + i * 1.7)
		var offset := Vector2.RIGHT.rotated(angle) * bubble_spread * (0.4 + 0.6 * pulse)
		var bubble := bubble_color
		bubble.a *= pulse
		draw_circle(offset, 1.5 + pulse * 1.5, bubble)
