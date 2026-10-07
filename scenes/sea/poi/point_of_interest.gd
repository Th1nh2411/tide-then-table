class_name PointOfInterest
extends Area2D
## A place worth visiting on the map (Cù Lao Chàm / Hội An setting). Has its
## own lamp so it shows in the dark, draws its name, and when the boat is
## inside and slow, `interact` runs `_interact()` (override it; it usually
## awaits `dialog.ask(...)`). Fishing spots keep away (group "pois").

@export var title: String = ""
@export var prompt_text: String = "E: Ghé"
## Radius of the visit area (px).
@export var reach: float = 45.0
## Boat must be slower than this (px/s) to visit.
@export var max_speed: float = 25.0
@export_group("Lamp")
## Hội An lantern red by default.
@export var lamp_color: Color = Color(1.0, 0.5, 0.35)
@export var lamp_radius: float = 70.0
@export var lamp_energy: float = 1.0
@export var lamp_offset: Vector2 = Vector2.ZERO
@export var label_offset: Vector2 = Vector2(0, -30)
@export_group("Refs")
@export var hud: SeaHud
@export var dialog: PoiDialog

var _boat: Boat
var _can_visit: bool = false
var _busy: bool = false
var _time: float = 0.0


func _ready() -> void:
	add_to_group("pois")
	var shape := CircleShape2D.new()
	shape.radius = reach
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	var lamp := make_lamp(lamp_color, lamp_radius, lamp_energy)
	lamp.position = lamp_offset
	add_child(lamp)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


## Warm radial light that shows through the night tint.
static func make_lamp(color: Color, radius: float, energy: float = 1.0) -> PointLight2D:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 64
	texture.height = 64
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	var light := PointLight2D.new()
	light.texture = texture
	light.texture_scale = radius * 2.0 / 64.0
	light.color = color
	light.energy = energy
	return light


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	var can := _boat != null and absf(_boat.speed) <= max_speed and not _busy
	if can != _can_visit:
		_can_visit = can
		if can:
			hud.show_prompt("%s %s" % [prompt_text, title])
		else:
			hud.hide_prompt()


func _unhandled_input(event: InputEvent) -> void:
	if _can_visit and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_visit()


func _visit() -> void:
	_busy = true
	_boat.speed = 0.0
	await _interact()
	_busy = false


## Override: what happens on a visit.
func _interact() -> void:
	pass


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var text_width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
	draw_string(font, label_offset - Vector2(text_width * 0.5, 0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 9,
		Color(1.0, 0.92, 0.75))


func _on_body_entered(body: Node2D) -> void:
	if body is Boat:
		_boat = body


func _on_body_exited(body: Node2D) -> void:
	if body == _boat:
		_boat = null
