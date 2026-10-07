extends Control
## Morning rest card between the night trip and the restaurant (6:00-15:00 is
## Rin's sleep, shown as one short screen): when Rin got back, what came home
## in the hold, fish orders delivered / expired (FishOrders), notes from night
## events, and the weather forecast for the next trip; then the restaurant.

const RESTAURANT_SCENE_PATH: String = "res://scenes/restaurant/restaurant_scene.tscn"

## For order texts (fish names).
@export var fish_catalog: FishCatalog
## Rolls the weather for the next trip (forecast shown here and in the phone).
@export var weather_catalog: WeatherCatalog

@onready var _return_label: Label = %ReturnLabel
@onready var _catch_label: Label = %CatchLabel
@onready var _order_label: Label = %OrderLabel
@onready var _sleep_label: Label = %SleepLabel
@onready var _wake_button: Button = %WakeButton


func _ready() -> void:
	var time := DayClock.format_minutes(GameState.return_minutes)
	if GameState.was_towed:
		_return_label.text = "Rin được cứu hộ kéo về bến lúc %s." % time
	else:
		_return_label.text = "Rin cập bến lúc %s." % time
	_catch_label.text = _catch_text()
	var order_lines := FishOrders.settle(fish_catalog)
	order_lines.append_array(GameState.trip_notes)
	GameState.trip_notes.clear()
	_order_label.text = "\n".join(order_lines)
	_order_label.visible = not order_lines.is_empty()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var weather := weather_catalog.pick(rng)
	GameState.weather_id = weather.id
	_sleep_label.text = "Rin về nhà ngủ một giấc... tới %02d:00 dậy mở quán.\nDự báo chuyến tới: %s (%s)." % [
		DayClock.shop_open_hour, weather.display_name, weather.forecast]
	_wake_button.pressed.connect(func() -> void: SceneRouter.go_to(RESTAURANT_SCENE_PATH))
	_wake_button.grab_focus()


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
