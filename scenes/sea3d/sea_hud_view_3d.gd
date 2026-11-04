class_name SeaHudView3D
extends Control
## The 3D sea's HUD, icon first (words in tooltips): a weathered plank top-left
## with the boat and clock, then meters for lamp oil, hull and the
## basket (fish count); the R action as key caps + an icon bottom-right; Rin's lines on the
## paper SpeechStrip bottom-left. No key card: the horror build shows no
## control hints (the pause menu's settings list the keys).
## SeaHud3D.update calls `refresh` every frame.

const SCREEN := Vector2(640, 360)
## Fish that fill the basket meter (it only shows how full the giỏ looks).
const BASKET_FULL := 8.0

var speech: SpeechStrip
var _time: Label
var _boat: Control
var _oil: MeterBar
var _hull: MeterBar
var _hold: MeterBar
var _fish: Label
var _prompt: HBoxContainer
var _prompt_key := ""


func _ready() -> void:
	size = SCREEN
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_plank()
	_prompt = HBoxContainer.new()
	_prompt.add_theme_constant_override("separation", 4)
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_prompt)
	speech = SpeechStrip.new()
	speech.default_speaker = "Rin"
	speech.text_width = 330.0
	add_child(speech)
	speech.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	speech.offset_left = 12
	speech.offset_top = -30
	speech.offset_bottom = -8
	speech.grow_vertical = Control.GROW_DIRECTION_BEGIN


func _build_plank() -> void:
	var parts := HudChips.plank(&"WoodPanel", 6)
	var panel: PanelContainer = parts[0]
	panel.position = Vector2(6, 4)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parts[1] as HBoxContainer).add_child(column)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 7)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(top)
	_boat = UiIcons.make("boat", 14, UiIcons.CREAM, Color("3c5e8b"))
	_boat.mouse_filter = Control.MOUSE_FILTER_PASS
	top.add_child(_boat)
	_time = HudChips.stat(top, "clock", Color("a4dddb"), "Giờ", 12)
	var gauges := HBoxContainer.new()
	gauges.add_theme_constant_override("separation", 6)
	gauges.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(gauges)
	_oil = HudChips.meter(gauges, "lamp", UiIcons.GOLD, "Dầu đèn", Color("de9e41"), 26)
	_hull = HudChips.meter(gauges, "wrench", Color("c7cfcc"), "Thân thuyền", Color("a8ca58"), 22)
	_hull.low = 0.3
	_hull.segments = 4
	_hold = HudChips.meter(gauges, "fish", Color("73bed3"), "Giỏ cá", Color("73bed3"), 22)
	_hold.low = 0.0
	_fish = HudChips.number(10)
	(_hold.get_parent() as HBoxContainer).add_child(_fish)


func _key_row(key: String, icon: String, color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cap := Label.new()
	cap.text = key
	cap.theme_type_variation = &"KeyLabel"
	cap.add_theme_font_size_override("font_size", 9)
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(cap)
	row.add_child(UiIcons.make(icon, 12, color))
	return row


func refresh(sea: SeaScene3D) -> void:
	_boat.tooltip_text = sea.boat_data.display_name
	_time.text = DayClock.get_time_text()
	_oil.set_value(sea.oil / maxf(sea.oil_capacity, 1.0))
	_hull.set_value(GameState.boat_hp / 100.0)
	var fish: int = sea.rod.basket.count() if sea.rod else 0
	_hold.set_value(clampf(fish / BASKET_FULL, 0.0, 1.0))
	HudChips.show_number(_fish, fish)
	_set_prompt(_prompt_spec(sea))
	if sea.message.text != speech.current:
		if sea.message.text == "":
			speech.clear()
		else:
			speech.say(sea.message.text, 0.0)


## [[key, icon], ...] + optional place name.
func _prompt_spec(sea: SeaScene3D) -> Array:
	if sea._at_dock():
		return [[["R", "house"]], ""]
	return [[], ""]


func _set_prompt(spec: Array) -> void:
	var key := str(spec)
	if key == _prompt_key:
		return
	_prompt_key = key
	for child in _prompt.get_children():
		_prompt.remove_child(child)
		child.queue_free()
	for pair: Array in spec[0]:
		_prompt.add_child(_key_row(str(pair[0]), str(pair[1]), UiIcons.CREAM))
	var place := str(spec[1])
	if place != "":
		var place_label := HudChips.number(11)
		place_label.text = place
		_prompt.add_child(place_label)
	_prompt.reset_size()
	var width := _prompt.get_combined_minimum_size().x
	_prompt.position = Vector2(SCREEN.x - width - 12.0, SCREEN.y - 26.0)
	UiFx.pop_in(_prompt)
