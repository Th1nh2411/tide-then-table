extends Control
## Morning rest card between the night trip and the restaurant (6:00-15:00 is
## Rin's sleep, shown as one short screen): when Rin got back, what came home
## in the hold, notes from night events, fish orders (ready or not), and the
## weather forecast for the next trip, and "Món mới!" when a new seafood (or
## last night's kitchen upgrade) unlocks dishes (DishBook); then the
## restaurant (autosaved here).
## Look: a page of Rin's notebook ("NotebookPanel") over a flat pixel dawn:
## red day tab, return time, fish pictures with counts, order rows with
## ticks, a yellow weather sticky note, "MỚI" dishes; full sentences live in
## tooltips (RestCardView builds the pieces).

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
@onready var _panel: PanelContainer = %Panel


func _ready() -> void:
	Sfx.ambience("sea")
	var time := DayClock.format_minutes(GameState.return_minutes)
	%DayLabel.text = "Ngày %d" % GameState.day
	UiFx.tilt(%DayLabel as Control, -3.0)
	_return_label.text = time
	var return_row := %ReturnRow as HBoxContainer
	return_row.add_child(UiIcons.make("leave" if GameState.was_towed else "anchor", 14, RestCardView.RED))
	return_row.move_child(return_row.get_child(-1), 0)
	return_row.tooltip_text = ("Rin được cứu hộ kéo về bến lúc %s." if GameState.was_towed else "Rin cập bến lúc %s.") % time
	return_row.mouse_filter = Control.MOUSE_FILTER_PASS
	_catch_label.text = _catch_text()
	_fill_catch()
	var notes := PackedStringArray(GameState.trip_notes)
	GameState.trip_notes.clear()
	for order: Dictionary in GameState.orders:
		%Orders.add_child(RestCardView.order_row(order, fish_catalog, FishOrders.has_fish_for(order)))
	_order_label.text = "\n".join(notes)
	_order_label.visible = not notes.is_empty()
	if menu:
		var fresh := DishBook.new_dishes(menu.dishes)
		if not fresh.is_empty():
			_order_label.add_sibling(RestCardView.new_dishes(fresh))
			Sfx.play("shutter")  # a photo of the new dish
			Sfx.play("catch")
			DishBook.mark_seen(fresh)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var weather := weather_catalog.pick(rng)
	GameState.weather_id = weather.id
	var note := RestCardView.weather_note(weather, _sleep_label)
	%Header.add_child(note)
	UiFx.tilt(note, 3.0)
	UiIcons.dress(_wake_button, "shop", 14, UiIcons.GOLD)
	_wake_button.text = "%02d:00" % DayClock.shop_open_hour
	UiFx.hover_lift(_wake_button, 0.06)
	_panel.draw.connect(func() -> void:  # taped to the dawn
		UiStickers.draw(_panel, "tape", Vector2(_panel.size.x - 18, 2)))
	_panel.modulate.a = 0.0
	_slide_in.call_deferred()
	# Second autosave: right after the trip, so the catch is never lost.
	SaveSystem.autosave("restaurant")
	_wake_button.pressed.connect(func() -> void: SceneRouter.go_to(RESTAURANT_SCENE_PATH))
	_wake_button.grab_focus()


func _slide_in() -> void:
	UiFx.tilt(_panel, 0.0)
	UiFx.settle(_panel, Vector2(0, -24), 0.05, -4.0)
	UiFx.stagger(%CatchRow as Control, 0.06, 0.3)


## Fish pictures with counts, the perfect count and the biggest catch.
func _fill_catch() -> void:
	var row := %CatchRow as HFlowContainer
	_catch_label.visible = GameState.last_catch.is_empty()
	var counts: Dictionary = {}  # FishData -> count, first-seen order
	var perfect := 0
	var biggest: InventoryItem = null
	for item: InventoryItem in GameState.last_catch:
		counts[item.fish] = int(counts.get(item.fish, 0)) + 1
		perfect += 1 if item.quality >= 1.0 else 0
		if item.fish.catch_method == FishData.CatchMethod.ROD and (biggest == null
				or item.fish.weight_kg(item.size) > biggest.fish.weight_kg(biggest.size)):
			biggest = item
	for fish: FishData in counts:
		row.add_child(RestCardView.fish_chip(fish, int(counts[fish])))
	if perfect > 0:
		row.add_child(RestCardView.icon_stat("star", str(perfect), "Con hoàn hảo"))
	if biggest:
		row.add_child(RestCardView.icon_stat("trophy", biggest.fish.weight_text(biggest.size),
			"To nhất: %s" % biggest.fish.display_name))
	row.tooltip_text = _catch_text()


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
