extends Control
## Morning rest card between the night trip and the restaurant (6:00-15:00 is
## Rin's sleep, shown as one short screen): when Rin got back, what came home
## in the hold, notes from night events, fish orders (ready or not), and the
## weather forecast for the next trip, and "Món mới!" when a new seafood (or
## last night's kitchen upgrade) unlocks dishes (DishBook); then the
## restaurant (autosaved here).

const RESTAURANT_SCENE_PATH: String = "res://scenes/restaurant3d/restaurant_scene_3d.tscn"

## For order texts (fish names).
@export var fish_catalog: FishCatalog
## Rolls the weather for the next trip (forecast shown here and in the phone).
@export var weather_catalog: WeatherCatalog
## For the "new dishes" card.
@export var menu: DishCatalog

@onready var _return_label: Label = %ReturnLabel
@onready var _catch_label: Label = %CatchLabel
@onready var _order_label: Label = %OrderLabel
@onready var _sleep_label: Label = %SleepLabel
@onready var _wake_button: Button = %WakeButton


func _ready() -> void:
	Sfx.ambience("sea")
	var time := DayClock.format_minutes(GameState.return_minutes)
	if GameState.was_towed:
		_return_label.text = "Rin được cứu hộ kéo về bến lúc %s." % time
	else:
		_return_label.text = "Rin cập bến lúc %s." % time
	_catch_label.text = _catch_text()
	var notes := PackedStringArray(GameState.trip_notes)
	GameState.trip_notes.clear()
	for order: Dictionary in GameState.orders:
		var ready := FishOrders.has_fish_for(order)
		notes.append("%s %s" % [FishOrders.describe(order, fish_catalog),
			"→ có cá rồi, khách sẽ ghé quán chiều nay" if ready else "→ chưa có cá đủ ký"])
	_order_label.text = "\n".join(notes)
	_order_label.visible = not notes.is_empty()
	if menu:
		var fresh := DishBook.new_dishes(menu.dishes)
		if not fresh.is_empty():
			_order_label.add_sibling(_new_dish_card(fresh))
			DishBook.mark_seen(fresh)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var weather := weather_catalog.pick(rng)
	GameState.weather_id = weather.id
	_sleep_label.text = "Rin về nhà ngủ một giấc... tới %02d:00 dậy mở quán.\nDự báo chuyến tới: %s (%s)." % [
		DayClock.shop_open_hour, weather.display_name, weather.forecast]
	# Second autosave: right after the trip, so the catch is never lost.
	SaveSystem.autosave("restaurant")
	_wake_button.pressed.connect(func() -> void: SceneRouter.go_to(RESTAURANT_SCENE_PATH))
	_wake_button.grab_focus()


## "Món mới!" and a chip per dish (its picture, or a plate in its colour).
func _new_dish_card(dishes: Array[DishData]) -> Control:
	var box := VBoxContainer.new()
	var title := Label.new()
	title.text = "Món mới!"
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	box.add_child(title)
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 10)
	box.add_child(chips)
	for dish in dishes:
		var chip := HBoxContainer.new()
		var plate := _DishIcon.new()
		plate.dish = dish
		chip.add_child(plate)
		var name_label := Label.new()
		name_label.text = "%s %dk" % [dish.display_name, dish.base_price]
		name_label.add_theme_font_size_override("font_size", 10)
		chip.add_child(name_label)
		chips.add_child(chip)
	Sfx.play("catch")
	return box


## A 16x16 dish picture (Art "dishes/<id>"), or a plate in its colour.
class _DishIcon extends Control:
	var dish: DishData

	func _ready() -> void:
		custom_minimum_size = Vector2(16, 16)

	func _draw() -> void:
		if not Art.draw(self, "dishes/" + dish.id, Rect2(Vector2.ZERO, Vector2(16, 16))):
			draw_circle(Vector2(8, 8), 7.0, Color.WHITE)
			draw_circle(Vector2(8, 7.5), 4.5, dish.color)


## e.g. "Mẻ đêm nay: Mực x2 · Ốc hương x6 / (3 con hoàn hảo · to nhất: Mực 520g)".
func _catch_text() -> String:
	if GameState.last_catch.is_empty():
		return "Đêm nay không mang về được gì."
	var counts: Dictionary = {}  # display name -> count, first-seen order
	var perfect := 0
	var biggest: InventoryItem = null
	for item: InventoryItem in GameState.last_catch:
		if item.fish.catch_method == FishData.CatchMethod.ROD and (biggest == null
				or item.fish.weight_kg(item.size) > biggest.fish.weight_kg(biggest.size)):
			biggest = item
		counts[item.fish.display_name] = counts.get(item.fish.display_name, 0) + 1
		if item.quality >= 1.0:
			perfect += 1
	var parts: PackedStringArray = []
	for fish_name: String in counts:
		parts.append("%s x%d" % [fish_name, counts[fish_name]])
	var extra := ""
	if biggest:
		extra = " · to nhất: %s %s" % [biggest.fish.display_name, biggest.fish.weight_text(biggest.size)]
	return "Mẻ đêm nay: %s\n(%d con hoàn hảo%s)" % [" · ".join(parts), perfect, extra]
