extends Control
## Restaurant screen (side view).
## Flow: prepare today's menu from storage -> open -> serve customers until
## the shift timer runs out (or the player closes early) -> leftovers go back
## to storage -> summary. Shift length comes from the sea trip (late = shorter).
## Once the menu sells out, customers can only order snacks (peanuts), so a
## poorly prepared menu earns little. A menu with few dishes lowers all prices.
## After the summary (with a 1-5 star rating) comes the upgrade shop, then
## the next day starts at sea (storage loses freshness overnight).

const SEA_SCENE_PATH: String = "res://scenes/sea/sea_scene.tscn"

## Full selling shift length in real seconds when back on time.
@export var base_shift_seconds: float = 180.0
@export var menu: DishCatalog
@export var fish_catalog: FishCatalog
## How many different dishes the menu can hold.
@export var menu_slots: int = 3
## Price multiplier by number of distinct dishes on the menu (index = count;
## higher counts use the last entry). Customers get bored of a tiny menu.
@export var variety_multipliers: Array[float] = [0.8, 0.8, 0.9, 1.0]
@export var message_seconds: float = 1.5
## Fridge upgrade: its value is the freshness lost overnight.
@export var fridge_upgrade: UpgradeData

var _plan: MenuPlan
var _time_left: float = 0.0
var _shift_running: bool = false
var _shift_over: bool = false
var _earned_today: int = 0
var _market_spent: int = 0
var _variety_count: int = 0
var _variety_multiplier: float = 1.0
var _sold_out_announced: bool = false
var _served: int = 0
var _left_angry: int = 0
var _message_token: int = 0

@onready var _customers: CustomerManager = $CustomerManager
@onready var _menu_panel: MenuSetupPanel = %MenuSetupPanel
@onready var _top_label: Label = %TopLabel
@onready var _storage_label: Label = %StorageLabel
@onready var _message_label: Label = %MessageLabel
@onready var _summary_panel: Control = %SummaryPanel
@onready var _summary_label: Label = %SummaryLabel
@onready var _next_day_button: Button = %NextDayButton
@onready var _close_early_button: Button = %CloseEarlyButton
@onready var _shop: UpgradeShop = %UpgradeShop


func _ready() -> void:
	_summary_panel.hide()
	_message_label.hide()
	_customers.customer_served.connect(_on_customer_served)
	_customers.customer_left_angry.connect(func() -> void: _left_angry += 1)
	_customers.message_requested.connect(_show_message)
	_next_day_button.pressed.connect(_on_continue_pressed)
	_shop.finished.connect(_start_next_day)
	(%RepairButton as RepairButton).repaired.connect(func(spent: int, fully: bool) -> void:
		_show_message("Đã sửa thuyền: -%dk%s" % [spent, "" if fully else " (chưa đủ tiền sửa hết)"]))
	_close_early_button.pressed.connect(func() -> void: _end_shift("Đóng quán sớm"))
	_close_early_button.hide()

	_plan = MenuPlan.new(menu_slots, GameState.money)
	_plan.changed.connect(_refresh_storage)
	_menu_panel.setup(_plan, menu, fish_catalog, variety_multipliers)
	_menu_panel.confirmed.connect(_open_shop)
	_menu_panel.show()
	_time_left = get_shift_seconds()
	_refresh_storage()


func get_shift_seconds() -> float:
	return base_shift_seconds * GameState.shift_ratio


func _open_shop() -> void:
	_menu_panel.hide()
	# Market produce is paid for now; unsold portions are wasted at closing.
	_market_spent = _plan.market_spent
	GameState.spend_money(_market_spent)
	_variety_count = _plan.variety_count()
	_variety_multiplier = MenuPlan.variety_multiplier(_variety_count, variety_multipliers)
	_shift_running = true
	_close_early_button.show()
	_customers.start_shift(_plan, _variety_multiplier)
	var late_text := ""
	if GameState.was_towed:
		late_text = " (bị kéo về, ca bán ngắn nhất)"
	elif GameState.shift_ratio < 1.0:
		late_text = " (về trễ, ca bán còn %d%%)" % roundi(GameState.shift_ratio * 100)
	_show_message("Quán mở cửa!" + late_text)
	_refresh_storage()


# Debug builds: F1 during menu setup adds one of every fish to storage,
# so the restaurant can be tested with F6 without a sea trip.
func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not OS.is_debug_build() or key == null or not key.pressed or key.physical_keycode != KEY_F1:
		return
	if not _menu_panel.visible:
		return
	for fish in fish_catalog.fish:
		GameState.storage.append(InventoryItem.new(fish, 1.0))
	_plan.changed.emit()  # refresh panel + storage line


func _process(delta: float) -> void:
	if _shift_running:
		_time_left = maxf(_time_left - delta, 0.0)
		if _time_left <= 0.0:
			_end_shift("Hết giờ bán!")
		elif _plan.is_sold_out() and not _sold_out_announced:
			_sold_out_announced = true
			_show_message("Menu đã hết món, khách chỉ còn gọi đậu phộng...")
	_top_label.text = "Ngày %d   Ca còn %d:%02d   Tiền %dk (hôm nay +%dk)" % [
		GameState.day, int(_time_left) / 60, int(_time_left) % 60, GameState.money, _earned_today]


func _end_shift(reason: String) -> void:
	if not _shift_running:
		return
	_shift_running = false
	_close_early_button.hide()
	_customers.stop_shift()
	_show_message(reason)
	# Let the dish on the stove finish before closing up.
	if _customers.is_cooking():
		await _customers.cooking_ended
	var leftover := _plan.total_portions()
	_plan.clear(GameState.storage)
	_shift_over = true
	var monotonous := _variety_multiplier < 1.0
	var variety_text := "Menu %d món" % _variety_count
	if monotonous:
		variety_text += " — đơn điệu, giá x%.1f" % _variety_multiplier
	var stars := DayRating.stars(_served, _left_angry, monotonous)
	GameState.last_rating = stars
	_summary_label.text = "%s\nĐÁNH GIÁ: %d/5 sao\nThu được: %dk   Tiền chợ: -%dk   Lãi: %dk\n%s\nKhách đã phục vụ: %d   Khách bỏ đi: %d\nPhần thừa: %d (hải sản trả về kho, rau bỏ đi)\n%s" % [
		reason, stars, _earned_today, _market_spent, _earned_today - _market_spent, variety_text,
		_served, _left_angry, leftover, _rating_hint(stars)]
	_summary_panel.show()
	_next_day_button.grab_focus()


func _on_customer_served(price: int, tip: int) -> void:
	_earned_today += price + tip
	_served += 1


func _refresh_storage() -> void:
	var lines: PackedStringArray = []
	if _shift_running:
		var menu_parts: PackedStringArray = []
		for dish in _plan.get_dishes():
			var left := _plan.get_portion_count(dish)
			menu_parts.append("%s %s" % [dish.display_name, ("còn %d" % left) if left > 0 else "(hết)"])
		lines.append("Menu: " + " · ".join(menu_parts))
	lines.append("Kho: " + _storage_text())
	_storage_label.text = "\n".join(lines)


func _show_message(text: String) -> void:
	_message_token += 1
	var token := _message_token
	_message_label.text = text
	_message_label.show()
	await get_tree().create_timer(message_seconds).timeout
	if token == _message_token:
		_message_label.hide()


## e.g. "Cua x2 (tươi 100), Cua x1 (tươi 65)": grouped by fish and freshness.
func _storage_text() -> String:
	var groups: Dictionary = {}  # "name|freshness" -> count, keeps first-seen order
	for item: InventoryItem in GameState.storage:
		var key := "%s|%d" % [item.fish.display_name, roundi(item.freshness)]
		groups[key] = groups.get(key, 0) + 1
	if groups.is_empty():
		return "trống"
	var parts: PackedStringArray = []
	for key: String in groups:
		var pieces := key.split("|")
		parts.append("%s x%d (tươi %s)" % [pieces[0], groups[key], pieces[1]])
	return ", ".join(parts)


func _rating_hint(stars: int) -> String:
	if stars >= 4:
		return "Khách khen nức nở, mai sẽ đông khách hơn!"
	if stars <= 2:
		return "Khách chê, mai sẽ vắng hơn..."
	return ""


func _on_continue_pressed() -> void:
	_summary_panel.hide()
	_shop.open()


func _start_next_day() -> void:
	var loss: float = float(GameState.get_upgrade_value(fridge_upgrade)) if fridge_upgrade else 35.0
	GameState.advance_day(loss)
	SceneRouter.go_to(SEA_SCENE_PATH)
