class_name MapOverlay
extends CanvasLayer
## The big map (M, at sea and in the restaurant; PhoneApp owns it): the same
## PhoneMap as the phone tab, almost full screen, with zone names, a legend
## and the distance home. Pauses the game; M or Esc closes it. Click = pin.

@export var panel_size: Vector2 = Vector2(600, 330)

var _opened_pause: bool = false
var _map: PhoneMap


func _ready() -> void:
	layer = 26
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = panel_size
	panel.theme_type_variation = &"PaperPanel"  # folded paper chart
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	var title := HBoxContainer.new()
	box.add_child(title)
	title.add_child(_label("BẢN ĐỒ", &"HeadingLabel", 12, true))
	title.add_child(_label("bấm: ghim · M / Esc: đóng", &"MutedLabel", 8, false))
	_map = PhoneMap.new()
	_map.label_size = 9
	_map.paper = Color("ebede9")  # chart on the cream paper
	_map.show_legend = true
	_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_map)
	hide()


func open() -> void:
	_opened_pause = not get_tree().paused
	get_tree().paused = true
	show()


func close() -> void:
	hide()
	if _opened_pause:
		get_tree().paused = false
		_opened_pause = false


func _label(text: String, variation: StringName, font_size: int, expand: bool) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.add_theme_font_size_override("font_size", font_size)
	if expand:
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label
