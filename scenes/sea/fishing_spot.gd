class_name FishingSpot
extends Area2D
## Bubbling patch of water with a limited number of casts.
## When the boat is inside and slow enough, `interact` requests fishing.
## Disappears once all casts are used; new spots spawn the next day.
## Each spot has a "featured" species that most casts bring up; its bubbles
## are tinted with that fish's color so the player can read the water. A
## "big shadow" spot hides a large, valuable fish (shadow drawn underneath).

signal fishable_changed(spot: FishingSpot, can_fish: bool)
signal fishing_requested(spot: FishingSpot)

## Boat must be slower than this (px/s) to start fishing.
@export var max_fishing_speed: float = 15.0
@export var bubble_color: Color = Color(1, 1, 1, 0.85)
@export var bubble_spread: float = 8.0
@export var blink_speed: float = 4.0
## How much the featured fish's color tints the bubbles.
@export var tint_strength: float = 0.6
@export var shadow_color: Color = Color(0.02, 0.05, 0.12, 0.55)
## Shadow length per hold cell of the featured fish.
@export var shadow_px_per_cell: float = 5.0
@export var aberrant_glow: Color = Color(0.5, 1.0, 0.9, 0.35)

## Set by the spawner before the spot enters the tree.
var zone: FishData.Zone = FishData.Zone.NEARSHORE
var casts_left: int = 3
## 0 = by the shore, 1 = far out (see CatchRoll.depth_at).
var depth: float = 0.0
## Species most casts here bring up (null = plain zone random).
var featured: FishData
## Chance a cast brings up `featured` instead of a zone/depth random fish.
var featured_chance: float = 0.7
## Passed to FishCatalog.pick_random for the non-featured casts.
var rarity_boost: float = 3.0
## Tonight's weather species multipliers (FishCatalog.pick_random).
var species_bonus: Dictionary = {}
var big_shadow: bool = false

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


## Species for the next cast.
func roll_fish(catalog: FishCatalog, rng: RandomNumberGenerator) -> FishData:
	if featured and rng.randf() < featured_chance:
		return featured
	return catalog.pick_random(zone, rng, FishData.CatchMethod.ROD, depth, rarity_boost, species_bonus)


## Prompt hint: the featured fish's name once it's in the Dex, else "???".
func hint_text() -> String:
	var fish_name := "???"
	if featured and int(GameState.caught_species.get(featured.id, 0)) > 0:
		fish_name = featured.display_name
	return "bóng cá lớn: %s" % fish_name if big_shadow else "có vẻ là %s" % fish_name


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
	if big_shadow and featured:
		_draw_shadow()
	if featured and featured.is_aberrant:
		var glow := aberrant_glow
		glow.a *= 0.6 + 0.4 * sin(_time * 3.0)
		draw_circle(Vector2.ZERO, bubble_spread * 2.2, glow)
	var color := bubble_color
	if featured:
		color = bubble_color.lerp(featured.color, tint_strength)
		color.a = bubble_color.a
	# A few bubbles pulsing out of phase reads as "something is down there".
	var count := 7 if big_shadow else 5
	var spread := bubble_spread * (1.4 if big_shadow else 1.0)
	for i in count:
		var angle := TAU * i / count + _time * 0.5
		var pulse := 0.5 + 0.5 * sin(_time * blink_speed + i * 1.7)
		var offset := Vector2.RIGHT.rotated(angle) * spread * (0.4 + 0.6 * pulse)
		var bubble := color
		bubble.a *= pulse
		draw_circle(offset, 1.5 + pulse * 1.5, bubble)


## Dark fish silhouette slowly circling under the bubbles.
func _draw_shadow() -> void:
	var length := shadow_px_per_cell * (featured.shape.size() + 3)
	var angle := _time * 0.4
	var center := Vector2.RIGHT.rotated(angle) * bubble_spread * 1.5
	draw_set_transform(center, angle + PI / 2.0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, length * 0.5, shadow_color)
	# Tail.
	var tail := Vector2(-length * 0.5, 0.0)
	draw_colored_polygon(PackedVector2Array([tail, tail + Vector2(-length * 0.25, -length * 0.3),
		tail + Vector2(-length * 0.25, length * 0.3)]), shadow_color)
	draw_set_transform(Vector2.ZERO)
