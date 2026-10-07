extends Control
## Restaurant screen (side view).
## Flow: prepare today's menu from storage -> open at 15:00 -> serve customers
## until closing at 24:00 (fixed real-time shift, or the player closes early)
## -> leftovers go back to storage -> summary.
## Service (Dave the Diver style): Rin walks with A/D, E at the kitchen door
## opens the KitchenView (cook from prepared trays onto the shelf); Bảo
## carries plates in order and cleans tables; Rin can carry a plate or clean
## a table too.
## Once the menu sells out, customers can only order snacks (peanuts), so a
## poorly prepared menu earns little. A menu with few dishes lowers all prices.
## After the summary (1-5 stars) nothing moves on by itself: pinned buttons
## let the player buy upgrades (phone "Nâng cấp" tab) whenever the shop isn't
## serving, and "Ra khơi" starts the next night (storage loses freshness).
## Regulars with a fish order: their fish is set aside before menu planning
## and they come in during the shift (CustomerManager); unserved fish go back
## to storage and overdue orders are cancelled at closing.

const SEA_SCENE_PATH: String = "res://scenes/sea/sea_scene.tscn"

## Real seconds for the whole shift (15:00 -> 24:00 on the displayed clock).
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
## After closing, waiting customers get this long to still be served.
@export var closing_grace_seconds: float = 15.0

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
## Regulars coming today (FishOrders.reserve_for_shift).
var _regular_visits: Array[Dictionary] = []
var _upgrade_button: Button
var _tutorial: RestaurantTutorial
var _sail_button: Button

@onready var _customers: CustomerManager = $CustomerManager
@onready var _menu_panel: MenuSetupPanel = %MenuSetupPanel
@onready var _top_label: Label = %TopLabel
@onready var _storage_label: Label = %StorageLabel
@onready var _message_label: Label = %MessageLabel
@onready var _summary_panel: Control = %SummaryPanel
@onready var _summary_label: Label = %SummaryLabel
@onready var _next_day_button: Button = %NextDayButton
@onready var _close_early_button: Button = %CloseEarlyButton
@onready var _phone: PhoneApp = $PhoneApp
@onready var _rin: RinWalker = $RinWalker
@onready var _kitchen_view: KitchenView = $KitchenView


func _ready() -> void:
	_summary_panel.hide()
	_message_label.hide()
	_customers.customer_served.connect(_on_customer_served)
	_customers.customer_left_angry.connect(func() -> void: _left_angry += 1)
	_customers.message_requested.connect(_show_message)
	_next_day_button.pressed.connect(_on_continue_pressed)
	_upgrade_button = _pin_button("Nâng cấp", Rect2(530, 26, 104, 20))
	_upgrade_button.pressed.connect(func() -> void: _phone.open_tab(PhoneApp.SHOP_TAB))
	_sail_button = _pin_button("Ra khơi  →", Rect2(520, 318, 114, 32))
	_sail_button.pressed.connect(_start_next_day)
	_sail_button.hide()
	_tutorial = RestaurantTutorial.new()
	_tutorial.customers = _customers
	_tutorial.kitchen_view = _kitchen_view
	add_child(_tutorial)
	_tutorial.tip_requested.connect(func(text: String) -> void: _show_message(text, _tutorial.tip_seconds))
	(%RepairButton as RepairButton).repaired.connect(func(spent: int, fully: bool) -> void:
		_show_message("Đã sửa thuyền: -%dk%s" % [spent, "" if fully else " (chưa đủ tiền sửa hết)"]))
	_close_early_button.pressed.connect(func() -> void: _end_shift("Đóng quán sớm"))
	_close_early_button.hide()

	_regular_visits = FishOrders.reserve_for_shift(menu)
	(%Decor as RestaurantDecor).setup(_customers.decor_level())
	_rin.kitchen_requested.connect(_open_kitchen)
	_rin.serve_requested.connect(_on_rin_serve)
	_rin.clean_requested.connect(func(seat: int) -> void: (_customers.tables as DiningTables).clean(seat))
	_rin.message_requested.connect(_show_message)
	_kitchen_view.closed.connect(func() -> void: _rin.active = _shift_running or not _customers.is_idle())
	_kitchen_view.carry_requested.connect(func(plate: DishShelf.Plate) -> void: _rin.carried = plate)
	_customers.regular_served.connect(func(who: String, price: int) -> void:
		_show_message("%s khen ngon, trả %dk!" % [who, price], 2.5))
	_plan = MenuPlan.new(menu_slots, GameState.money)
	_plan.changed.connect(_refresh_storage)
	_menu_panel.setup(_plan, menu, fish_catalog, variety_multipliers)
	_menu_panel.confirmed.connect(_open_shop)
	_menu_panel.show()
	_time_left = get_shift_seconds()
	_refresh_storage()


func get_shift_seconds() -> float:
	return base_shift_seconds


func _open_shop() -> void:
	_menu_panel.hide()
	# Market produce is paid for now; unsold portions are wasted at closing.
	_market_spent = _plan.market_spent
	GameState.spend_money(_market_spent)
	_variety_count = _plan.variety_count()
	_variety_multiplier = MenuPlan.variety_multiplier(_variety_count, variety_multipliers)
	_shift_running = true
	_close_early_button.show()
	_upgrade_button.hide()
	_customers.start_shift(_plan, _variety_multiplier, _regular_visits)
	_rin.active = true
	_show_message("Quán mở cửa!")
	_tutorial.on_shop_opened()
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
	var progress := 1.0 - _time_left / get_shift_seconds()
	DayClock.set_progress(progress, DayClock.shop_open_hour, DayClock.shop_close_hour)
	_top_label.text = "Ngày %d   %s (đóng cửa %02d:00)   Tiền %dk (hôm nay +%dk)" % [
		GameState.day, DayClock.get_time_text(), DayClock.shop_close_hour, GameState.money, _earned_today]


func _end_shift(reason: String) -> void:
	if not _shift_running:
		return
	_shift_running = false
	_close_early_button.hide()
	_customers.stop_shift()
	_show_message(reason)
	# Customers already inside can still be served for a while.
	var waited := 0.0
	while not _customers.is_idle() and waited < closing_grace_seconds:
		await get_tree().process_frame
		waited += get_process_delta_time()
	_customers.clear_room()
	while not _customers.is_idle():  # the last ones finish eating
		await get_tree().process_frame
	var cooking: CookingOverlay = $CookingOverlay
	while cooking.is_running():
		await get_tree().process_frame
	if _kitchen_view.visible:
		_kitchen_view.close()
	_rin.active = false
	_rin.carried = null
	var leftover := _plan.total_portions()
	_plan.clear(GameState.storage)
	# Plates left on the shelf are wasted; uncooked trays go back to storage.
	for visit in _customers.uncooked_regular_visits():
		FishOrders.release(visit)
	var order_lines := FishOrders.expire_after_shift(fish_catalog)
	_shift_over = true
	var monotonous := _variety_multiplier < 1.0
	var variety_text := "Menu %d món" % _variety_count
	if monotonous:
		variety_text += " — đơn điệu, giá x%.1f" % _variety_multiplier
	var stars := DayRating.stars(_served, _left_angry, monotonous)
	GameState.last_rating = stars
	GameState.add_day_record({"day": GameState.day, "earned": _earned_today, "market": _market_spent,
		"rating": stars, "served": _served, "left": _left_angry})
	_summary_label.text = "%s\nĐÁNH GIÁ: %d/5 sao\nThu được: %dk   Tiền chợ: -%dk   Lãi: %dk\n%s\nKhách đã phục vụ: %d   Khách bỏ đi: %d\nPhần thừa: %d (hải sản trả về kho, rau bỏ đi)\n%s%s" % [
		reason, stars, _earned_today, _market_spent, _earned_today - _market_spent, variety_text,
		_served, _left_angry, leftover, _rating_hint(stars),
		("\n" + "\n".join(order_lines)) if not order_lines.is_empty() else ""]
	_summary_panel.show()
	_next_day_button.grab_focus()


func _open_kitchen() -> void:
	if _rin.carried:
		# Coming back in with a plate: put it back on the shelf if there's room.
		if _customers.shelf.add(_rin.carried):
			_rin.carried = null
		else:
			_show_message("Kệ đầy, bưng món đang cầm ra trước đã")
			return
	_rin.active = false
	_kitchen_view.open(_plan)


func _on_rin_serve(seat: int) -> void:
	if _customers.serve_at(seat, _rin.carried):
		_rin.carried = null
	else:
		_show_message("Bàn %d không gọi món này" % (seat + 1))


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
	if not _regular_visits.is_empty():
		var parts: PackedStringArray = []
		for visit in _regular_visits:
			var item: InventoryItem = visit["item"]
			parts.append("%s %s cho %s" % [item.fish.display_name, item.fish.weight_text(item.size), visit["order"]["who"]])
		lines.append("Để riêng: " + ", ".join(parts))
	_storage_label.text = "\n".join(lines)


func _show_message(text: String, seconds: float = message_seconds) -> void:
	_message_token += 1
	var token := _message_token
	_message_label.text = text
	_message_label.show()
	await get_tree().create_timer(seconds).timeout
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


## Summary closed: the evening is free — upgrade, repair, then sail.
func _on_continue_pressed() -> void:
	_summary_panel.hide()
	_upgrade_button.show()
	_sail_button.show()
	_tutorial.on_evening()


func _pin_button(text: String, rect: Rect2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 10)
	$HUD.add_child(button)
	return button


func _start_next_day() -> void:
	var loss: float = float(GameState.get_upgrade_value(fridge_upgrade)) if fridge_upgrade else 35.0
	GameState.advance_day(loss)
	# Morning messages: maybe a new fish order (shown at sea and in the phone).
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	FishOrders.roll_new_order(rng, fish_catalog)
	SceneRouter.go_to(SEA_SCENE_PATH)
