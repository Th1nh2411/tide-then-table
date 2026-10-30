class_name NewCatchCard
extends CanvasLayer
## "NEW!" card for a species caught for the first time (HoldManager's
## `new_species_caught`): its shadow first, then it's slowly revealed with a
## flash, then the NEW badge, its name and weight. Space / E / click closes
## it once revealed. Pauses the game unless something else already did
## (the hold's overflow window stays in charge then). More than one in a
## row (a net) queue up.
## Look: a taped paper card (tilted) with the fish; "NEW!" is a yellow burst
## sticker (stickers/burst_new.png) that slams onto its corner with a shake,
## the name in Paytone ink, the weight on a paper tag, a Space key cap.

@export var shadow_seconds: float = 0.8
@export var reveal_seconds: float = 1.1

var _queue: Array[Dictionary] = []  # {"fish", "size"}
var _opened_pause: bool = false
var _can_close: bool = false
var _time: float = 0.0

var _portrait: FishPortrait
var _badge: Control
var _card: PanelContainer
var _name_label: Label
var _weight_label: Label
var _hint: Control


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
	_name_label.text = fish.display_name
	_weight_label.text = fish.weight_text(float(entry["size"]))
	_name_label.get_parent().modulate.a = 0.0
	UiFx.tilt(_card, -2.0)
	UiFx.settle(_card, Vector2(0, -30), 0.0, -9.0)
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
		UiFx.stamp(_badge, _card)
		var info := _name_label.get_parent() as Control
		info.modulate.a = 1.0
		UiFx.pop_in(info, 0.12)
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
	dim.color = Color(0.035, 0.04, 0.08, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var holder := Control.new()  # free layout: the sticker breaks the card edge
	holder.custom_minimum_size = Vector2(230, 168)
	center.add_child(holder)
	_card = PanelContainer.new()
	_card.theme_type_variation = &"PaperPanel"
	_card.position = Vector2(10, 14)
	_card.custom_minimum_size = Vector2(206, 0)
	holder.add_child(_card)
	_card.draw.connect(func() -> void:
		UiStickers.draw(_card, "tape", Vector2(_card.size.x * 0.5, 1)))
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 4)
	_card.add_child(box)
	var frame := PanelContainer.new()  # the fish in a dark sea-blue window
	var sea := StyleBoxFlat.new()
	sea.bg_color = Color("172038")
	sea.border_color = Color("090a14")
	sea.set_border_width_all(2)
	sea.anti_aliasing = false
	frame.add_theme_stylebox_override("panel", sea)
	box.add_child(frame)
	_portrait = FishPortrait.new()
	_portrait.custom_minimum_size = Vector2(150, 80)
	frame.add_child(_portrait)
	var info := HBoxContainer.new()
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 6)
	box.add_child(info)
	_name_label = Label.new()
	_name_label.theme_type_variation = &"TitleLabel"
	_name_label.add_theme_font_size_override("font_size", 14)
	_name_label.add_theme_color_override("font_color", Color("090a14"))
	_name_label.add_theme_constant_override("outline_size", 0)
	info.add_child(_name_label)
	var tag := PanelContainer.new()
	tag.theme_type_variation = &"TagPanel"
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_child(tag)
	_weight_label = Label.new()
	_weight_label.theme_type_variation = &"CardLabel"
	_weight_label.add_theme_font_size_override("font_size", 9)
	tag.add_child(_weight_label)
	_badge = Control.new()
	_badge.size = Vector2(64, 44)
	_badge.position = Vector2(holder.custom_minimum_size.x - 70, -4)
	holder.add_child(_badge)
	var burst := TextureRect.new()
	burst.texture = UiStickers.texture("burst_new")
	burst.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	burst.set_anchors_preset(Control.PRESET_FULL_RECT)
	_badge.add_child(burst)
	var new_label := Label.new()
	new_label.text = "NEW!"
	new_label.theme_type_variation = &"TitleLabel"
	new_label.add_theme_font_size_override("font_size", 13)
	new_label.add_theme_color_override("font_color", Color("e0302b"))
	new_label.add_theme_constant_override("outline_size", 3)
	new_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	new_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	new_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_badge.add_child(new_label)
	_badge.rotation_degrees = 12.0
	var key := Label.new()
	key.text = "Space"
	key.theme_type_variation = &"KeyLabel"
	key.add_theme_font_size_override("font_size", 8)
	key.position = Vector2(holder.custom_minimum_size.x - 52, 142)
	holder.add_child(key)
	_hint = key
