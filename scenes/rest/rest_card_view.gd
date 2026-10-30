class_name RestCardView
extends RefCounted
## Pieces of the morning rest card (a page of Rin's notebook): fish chips
## (picture + "x2"), order rows (fish + who + tick / cross), the weather
## sticky note, the "MỚI" dish strip. Pictures and numbers, few words.

const INK := Color("090a14")
const RED := Color("a53030")
const MUTED := Color("394a50")
## WeatherData.id -> icon.
const WEATHER_ICONS := {"calm": "wave", "moon": "moon", "rain": "info", "wind": "wave"}


static func label(text: String, size: int = 10, variation: StringName = &"InkLabel") -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = variation
	l.add_theme_font_size_override("font_size", size)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


## Paytone number in ink (no outline): times, counts.
static func number(text: String, size: int = 12) -> Label:
	var l := label(text, size, &"TitleLabel")
	l.add_theme_color_override("font_color", INK)
	l.add_theme_constant_override("outline_size", 0)
	return l


static func fish_picture(fish: FishData, size: Vector2 = Vector2(38, 22)) -> FishPortrait:
	var pic := FishPortrait.new()
	pic.fish = fish
	pic.custom_minimum_size = size
	pic.mouse_filter = Control.MOUSE_FILTER_PASS
	pic.tooltip_text = fish.display_name
	return pic


## Picture + "x2" for one species in last night's catch.
static func fish_chip(fish: FishData, count: int) -> HBoxContainer:
	var chip := HBoxContainer.new()
	chip.add_theme_constant_override("separation", 1)
	chip.add_child(fish_picture(fish))
	chip.add_child(number("x%d" % count, 10))
	return chip


## Icon + value, e.g. star + 3 perfect, trophy + "Mực 520g".
static func icon_stat(id: String, text: String, tooltip: String, color: Color = RED) -> HBoxContainer:
	var row := UiIcons.pair(id, text, 12, color, &"CardLabel", 9)
	row.tooltip_text = tooltip
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	return row


## One fish order: fish picture, who, tick (fish ready) or cross.
static func order_row(order: Dictionary, catalog: FishCatalog, ready: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.tooltip_text = FishOrders.describe(order, catalog)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	for fish in catalog.fish:
		if fish.id == str(order["fish"]):
			row.add_child(fish_picture(fish, Vector2(24, 14)))
	row.add_child(label(str(order["who"]), 9, &"CardLabel"))
	row.add_child(UiIcons.make("check" if ready else "close", 12, Color("468232") if ready else RED))
	return row


## Yellow sticky note with the next trip's weather (forecast in the tooltip).
static func weather_note(weather: WeatherData, name_label: Label) -> PanelContainer:
	var note := PanelContainer.new()
	note.theme_type_variation = &"TagPanel"
	note.tooltip_text = "Dự báo chuyến tới: %s" % weather.forecast
	note.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note.add_child(row)
	row.add_child(UiIcons.make(str(WEATHER_ICONS.get(weather.id, "wave")), 14, Color("253a5e")))
	name_label.reparent(row)
	name_label.text = weather.display_name
	name_label.theme_type_variation = &"CardLabel"
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.custom_minimum_size = Vector2.ZERO
	name_label.remove_theme_color_override("font_color")
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	return note


## "MỚI" stamp + dish pictures with coin prices.
static func new_dishes(dishes: Array[DishData]) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var stamp := label("MỚI", 10, &"BadgeLabel")
	row.add_child(stamp)
	UiFx.tilt(stamp, -6.0)
	for dish in dishes:
		var chip := HBoxContainer.new()
		chip.add_theme_constant_override("separation", 2)
		chip.tooltip_text = dish.display_name
		chip.mouse_filter = Control.MOUSE_FILTER_PASS
		var plate := DishIcon.new()
		plate.dish = dish
		chip.add_child(plate)
		chip.add_child(label("%dk" % dish.base_price, 9, &"PriceLabel"))
		row.add_child(chip)
	return row


## A 16x16 dish picture (Art "dishes/<id>"), or a plate in its colour.
class DishIcon extends Control:
	var dish: DishData

	func _ready() -> void:
		custom_minimum_size = Vector2(16, 16)

	func _draw() -> void:
		if not Art.draw(self, "dishes/" + dish.id, Rect2(Vector2.ZERO, Vector2(16, 16))):
			draw_rect(Rect2(1, 2, 14, 12), Color("090a14"))
			draw_rect(Rect2(2, 3, 12, 10), Color("ebede9"))
			draw_rect(Rect2(5, 5, 6, 6), dish.color)
