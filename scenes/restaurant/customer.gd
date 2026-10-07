class_name Customer
extends Control
## A customer: walks in, sits at a table and orders, shows an order bubble
## and a patience bar, waits until the dish is cooked (Rin, on click) and
## carried out (Bảo, or Rin helping), then walks out. Placeholder drawing only.
## Special kinds: a regular coming for their fish order (name tag, gold
## bubble, more patient) and a well-off customer (gold shirt, pays more).

signal clicked(customer: Customer)
signal patience_ran_out(customer: Customer)

## WAITING = ordered; COOKING = Rin is cooking it; READY = dish on the
## counter or being carried out.
enum State { WALKING_IN, WAITING, COOKING, READY, LEAVING }

## Seconds from full patience to leaving.
@export var patience_seconds: float = 45.0
@export var walk_seconds: float = 1.5
@export var body_size: Vector2 = Vector2(18, 34)
@export var bubble_size: Vector2 = Vector2(96, 22)

var dish: DishData
## Ingredients of the menu portion this customer ordered
## (empty for market dishes).
var ingredients: Array[InventoryItem] = []
## 1.0 = full patience, 0.0 = leaving.
var patience: float = 1.0
var state: State = State.WALKING_IN
## Set for a regular eating their order (FishOrders); empty otherwise.
var regular_name: String = ""
## The order Dictionary and price for a regular.
var order: Dictionary = {}
## Well-off customer (decor upgrade): pays more, less patient.
var rich: bool = false
## Price multiplier of the cooked dish (1.0 from Bảo, more if Rin seasoned it).
var cook_multiplier: float = 1.0

var _shirt_color: Color


func _ready() -> void:
	size = body_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	_shirt_color = Color.from_hsv(randf(), 0.5, 0.85)
	if rich:
		_shirt_color = Color(0.95, 0.8, 0.3)
	elif regular_name:
		_shirt_color = Color(0.3, 0.5, 0.45)


func walk_to(target: Vector2) -> void:
	var tween := create_tween()
	tween.tween_property(self, "position", target, walk_seconds)
	await tween.finished
	if state == State.WALKING_IN:
		state = State.WAITING


func set_cooking(cooking: bool) -> void:
	state = State.COOKING if cooking else State.WAITING


func set_ready() -> void:
	state = State.READY


## Walk to the door and disappear.
func leave(door_position: Vector2) -> void:
	state = State.LEAVING
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween := create_tween()
	tween.tween_property(self, "position", door_position, walk_seconds)
	tween.tween_callback(queue_free)


func _process(delta: float) -> void:
	# Patience drops from sitting down until the dish arrives.
	if state == State.WAITING or state == State.COOKING or state == State.READY:
		patience = maxf(patience - delta / patience_seconds, 0.0)
		if patience <= 0.0:
			patience_ran_out.emit(self)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT \
			and state != State.WALKING_IN and state != State.LEAVING:
		accept_event()
		clicked.emit(self)


func _draw() -> void:
	# Body + head.
	draw_rect(Rect2(Vector2(0, 12), Vector2(body_size.x, body_size.y - 12)), _shirt_color)
	draw_circle(Vector2(body_size.x * 0.5, 6), 6, Color(0.95, 0.8, 0.65))
	if rich:
		draw_rect(Rect2(Vector2(body_size.x * 0.5 - 1, 14), Vector2(2, 8)), Color(0.6, 0.15, 0.15))  # tie
	if state == State.WAITING or state == State.COOKING or state == State.READY:
		_draw_order_bubble()


func _draw_order_bubble() -> void:
	var font := ThemeDB.fallback_font
	var origin := Vector2((body_size.x - bubble_size.x) * 0.5, -bubble_size.y - 10)
	var bubble_color := Color(1.0, 0.88, 0.5, 0.95) if regular_name else Color(1, 1, 1, 0.92)
	draw_rect(Rect2(origin, bubble_size), bubble_color)
	draw_rect(Rect2(origin + Vector2(3, 3), Vector2(8, 8)), dish.color)
	var text_color := Color(0.15, 0.1, 0.1)
	draw_string(font, origin + Vector2(14, 10), dish.display_name, HORIZONTAL_ALIGNMENT_LEFT,
		bubble_size.x - 16, 8, text_color)
	if regular_name:
		draw_string(font, origin + Vector2(0, -3), "%s (đặt trước)" % regular_name, HORIZONTAL_ALIGNMENT_LEFT,
			-1, 8, Color(1.0, 0.9, 0.55))
	var status := "Bấm để nấu"
	if state == State.COOKING:
		status = "Rin đang nấu"
	elif state == State.READY:
		status = "Món xong, chờ bưng"
	draw_string(font, origin + Vector2(14, 19), status, HORIZONTAL_ALIGNMENT_LEFT, bubble_size.x - 16, 7, text_color)
	# Patience bar under the bubble: green -> red.
	var bar := Rect2(origin + Vector2(0, bubble_size.y + 2), Vector2(bubble_size.x, 3))
	draw_rect(bar, Color(0, 0, 0, 0.5))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * patience, bar.size.y)),
		Color(1, 0.3, 0.3).lerp(Color(0.3, 0.9, 0.4), patience))
