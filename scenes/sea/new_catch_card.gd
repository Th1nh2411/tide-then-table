class_name NewCatchCard
extends CanvasLayer
## "NEW!" card for a species caught for the first time (HoldManager's
## `new_species_caught`): its shadow first, then it's slowly revealed with a
## flash, then the NEW badge, its name and weight. Space / E / click closes
## it once revealed. Pauses the game unless something else already did
## (the hold's overflow window stays in charge then). More than one in a
## row (a net) queue up.

@export var shadow_seconds: float = 0.8
@export var reveal_seconds: float = 1.1

var _queue: Array[Dictionary] = []  # {"fish", "size"}
var _opened_pause: bool = false
var _can_close: bool = false
var _time: float = 0.0

var _portrait: FishPortrait
var _badge: Label
var _name_label: Label
var _hint: Label


func _ready() -> void:
	layer = 24
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	hide()


func show_fish(fish: FishData, size: float) -> void:
	_queue.append({"fish": fish, "size": size})
	if not visible:
		_next()


func _next() -> void:
	if _queue.is_empty():
		hide()
		if _opened_pause:
			get_tree().paused = false
			_opened_pause = false
		return
	var entry: Dictionary = _queue.pop_front()
	var fish: FishData = entry["fish"]
	if not visible:
		_opened_pause = not get_tree().paused
		get_tree().paused = true
	show()
	_portrait.fish = fish
	_portrait.silhouette = 1.0
	_portrait.mystery = true
	_portrait.flash = 0.0
	_badge.visible = false
	_name_label.text = "%s · %s" % [fish.display_name, fish.weight_text(float(entry["size"]))]
	_name_label.modulate.a = 0.0
	_hint.visible = false
	_can_close = false
	_time = 0.0
	Sfx.play("pop")


func _process(delta: float) -> void:
	if not visible or _can_close:
		return
	_time += delta
	var reveal := clampf((_time - shadow_seconds) / reveal_seconds, 0.0, 1.0)
	_portrait.mystery = reveal <= 0.0
	_portrait.silhouette = 1.0 - reveal
	_portrait.flash = sin(reveal * PI)
	if reveal >= 1.0:
		_badge.visible = true
		_name_label.modulate.a = 1.0
		_hint.visible = true
		_can_close = true
		Sfx.play("shutter")
		Sfx.play("catch")


func _input(event: InputEvent) -> void:
	if not visible:
		return
	get_viewport().set_input_as_handled()  # nothing under the card reacts
	var click := event as InputEventMouseButton
	var pressed := event.is_action_pressed("cast") or event.is_action_pressed("interact") \
		or (click != null and click.pressed)
	if pressed and _can_close:
		_next()
	elif pressed:  # skip the slow reveal
		_time = shadow_seconds + reveal_seconds


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.2, 0.97)
	style.border_color = Color(1.0, 0.85, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	_badge = _label("NEW!", Color(1.0, 0.85, 0.3), 14)
	box.add_child(_badge)
	_portrait = FishPortrait.new()
	_portrait.custom_minimum_size = Vector2(150, 80)
	box.add_child(_portrait)
	_name_label = _label("", Color.WHITE, 11)
	box.add_child(_name_label)
	_hint = _label("Space", Color(0.6, 0.65, 0.7), 8)
	box.add_child(_hint)


func _label(text: String, color: Color, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	return label
