extends Control
## Restaurant screen: a sidewalk seafood spot seen top-down (StreetRoom).
## Flow: prepare today's menu from storage -> open at 15:00 -> serve customers
## until closing at 24:00 (fixed real-time shift, or the player closes early)
## -> leftovers go back to storage -> summary.
## Service (Dave the Diver style): Bảo is the chef (ChefBao: cooks every
## steamed / stir-fried dish by himself and puts it on the plate table); Rin
## is the waiter: WASD (+ Shift dash), E acts on the cell he faces — carry
## plates out, clean tables — and near the kitchen a menu chip / number key
## on one of his rows grills a dish (charcoal grill, compact minigame, no
## pop-up) or pours a beer tower.
## Rau muống and beer are always on the menu: their goods are bought at Cô
## Năm's grocery next door (E in front of the counter opens her list,
## MarketPanel; before opening or mid-shift); leftovers are thrown away at
## closing. Once the seafood sells out, customers only order those, so a poorly prepared menu earns little. A menu with
## few dishes lowers all prices.
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
## Cutscenes that can play after the summary (first eligible one, once).
@export var after_shift_cutscenes: Array[Cutscene] = []
## How close Rin must be to someone to talk (px).
@export var talk_reach: float = 22.0

var _plan: MenuPlan
var _time_left: float = 0.0
var _shift_running: bool = false
var _shift_over: bool = false
## Closed to new customers, still serving the ones inside.
var _closing: bool = false
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
var _renovate_button: Button
var _dialogue_box: DialogueBox
var _tutorial: RestaurantTutorial
var _sail_button: Button
var _market_panel: MarketPanel

@onready var _customers: CustomerManager = $CustomerManager
@onready var _menu_panel: MenuSetupPanel = %MenuSetupPanel
@onready var _message_label: Label = %MessageLabel
@onready var _summary_panel: Control = %SummaryPanel
@onready var _summary_label: Label = %SummaryLabel
@onready var _next_day_button: Button = %NextDayButton
@onready var _close_early_button: Button = %CloseEarlyButton
@onready var _renovation: RenovationMode = $RenovationMode
@onready var _room: StreetRoom = $World/Room
@onready var _chef: ChefBao = $World/People/Bao
@onready var _cutscene: CutscenePlayer = $CutscenePlayer
@onready var _rin: RinChef = $World/People/Rin
@onready var _kitchen: KitchenStation = $KitchenStation
@onready var _board: MenuBoard = $World/People/MenuBoard
@onready var _stall: MarketStall = $MarketStall


func _ready() -> void:
	_summary_panel.hide()
	_message_label.hide()
	_customers.customer_served.connect(_on_customer_served)
	_customers.customer_left_angry.connect(func() -> void: _left_angry += 1)
	_customers.message_requested.connect(_show_message)
	_next_day_button.pressed.connect(_on_continue_pressed)
	_board.clicked.connect(func() -> void:  # the LED sign opens menu planning
		_menu_panel.show()
		_menu_panel.move_to_front())
	_renovate_button = _pin_button("Sửa quán", Rect2(292, 42, 85, 18))
	_renovate_button.pressed.connect(_open_renovation)
	_renovation.finished.connect(_on_renovation_finished)
	_room.kitchen_level = GameState.get_upgrade_level(_renovation.kitchen_upgrade.id)
	_room.fridge_level = GameState.get_upgrade_level(_renovation.fridge_upgrade.id)
	# The minigame pops over the road below the kitchen (middle of the pavement).
	var cooking_panel := $CookingOverlay/Panel as Control
	cooking_panel.offset_left = 205.0
	cooking_panel.offset_right = 435.0
	cooking_panel.offset_top = 212.0
	cooking_panel.offset_bottom = 328.0
	_sail_button = _pin_button("Ra khơi  →", Rect2(520, 318, 114, 32))
	_sail_button.pressed.connect(_start_next_day)
	_sail_button.hide()
	_tutorial = RestaurantTutorial.new()
	_tutorial.customers = _customers
	_tutorial.kitchen = _kitchen
	add_child(_tutorial)
	_tutorial.tip_requested.connect(func(text: String) -> void: _show_message(text, _tutorial.tip_seconds))
	_tutorial.on_restaurant_ready.call_deferred()
	(%RepairButton as RepairButton).repaired.connect(func(spent: int, fully: bool) -> void:
		_show_message("Đã sửa thuyền: -%dk%s" % [spent, "" if fully else " (chưa đủ tiền sửa hết)"]))
	_close_early_button.pressed.connect(func() -> void: _end_shift("Đóng quán sớm"))
	_close_early_button.hide()

	_chef.message_requested.connect(_show_message.bind(2.5))
	_regular_visits = FishOrders.reserve_for_shift(menu)
	_kitchen.message_requested.connect(_show_message)
	_stall.message_requested.connect(_show_message.bind(2.0))
	_market_panel = MarketPanel.new()
	_market_panel.stall = _stall
	add_child(_market_panel)
	_stall.browse_requested.connect(_market_panel.open_panel)
	_stall.bought.connect(func(_dish: DishData, cost: int) -> void: _market_spent += cost)
	_rin.interacted.connect(_on_rin_interacted)
	_dialogue_box = DialogueBox.new()
	add_child(_dialogue_box)
	_customers.regular_served.connect(func(who: String, price: int) -> void:
		_show_message("%s khen ngon, trả %dk!" % [who, price], 2.5))
	_plan = MenuPlan.new(menu_slots)
	_kitchen.setup(_plan)
	_chef.setup(_plan)
	_menu_panel.setup(_plan, menu, fish_catalog, variety_multipliers)
	_menu_panel.confirmed.connect(_open_shop)
	_menu_panel.hide()  # opened by clicking the LED sign (MenuBoard)
	_time_left = get_shift_seconds()


func get_shift_seconds() -> float:
	return base_shift_seconds


func _open_shop() -> void:
	_menu_panel.hide()
	_variety_count = _plan.variety_count()
	_variety_multiplier = MenuPlan.variety_multiplier(_variety_count, variety_multipliers)
	_shift_running = true
	_close_early_button.show()
	_renovate_button.hide()
	_customers.start_shift(_plan, _variety_multiplier, _regular_visits)
	_show_message("Quán mở cửa!")
	_tutorial.on_shop_opened()


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
	_plan.changed.emit()  # refresh the menu panel


func _process(delta: float) -> void:
	# Rin walks freely whenever no panel covers the room.
	_rin.active = not ($CookingOverlay.is_running() or _kitchen.busy or _renovation.visible
		or _menu_panel.visible or _summary_panel.visible or _market_panel.visible)
	_rin.kitchen_open = _shift_running or _closing
	_board.clickable = not _shift_running and not _shift_over and not _closing and _rin.active
	_chef.serving = _rin.kitchen_open
	_rin.carrying_goods = _stall.bag.total() > 0
	if _shift_running:
		_time_left = maxf(_time_left - delta, 0.0)
		if _time_left <= 0.0:
			_end_shift("Hết giờ bán!")
		elif _plan.is_sold_out() and not _sold_out_announced:
			_sold_out_announced = true
			_show_message("Hết hải sản, khách chỉ còn gọi rau muống, tháp bia...")
	var progress := 1.0 - _time_left / get_shift_seconds()
	DayClock.set_progress(progress, DayClock.shop_open_hour, DayClock.shop_close_hour)
	# No top line (clock, money) or storage line: the LED board shows the menu,
	# money is in the summary / phone, storage in the phone (J).


func _end_shift(reason: String) -> void:
	if not _shift_running:
		return
	_shift_running = false
	_closing = true
	_close_early_button.hide()
	_customers.stop_shift()
	if _customers.is_idle():
		_show_message(reason)
	else:
		_show_message("%s Không nhận khách mới, phục vụ nốt khách trong quán." % reason, 3.0)
	# Everyone inside gets served and eats (or runs out of patience) first.
	while not _customers.is_idle():
		await get_tree().process_frame
	_closing = false
	var cooking: CookingOverlay = $CookingOverlay
	while cooking.is_running():
		await get_tree().process_frame
	_rin.carried = null
	_customers.shelf.clear()  # plates left on the table are wasted
	_chef.clear()
	var leftover := _plan.total_portions()
	_plan.clear(GameState.storage)
	_stall.open = false
	_stall.store_all()  # whatever is still in Rin's bag
	_market_panel.close_panel()
	var wasted_produce := _stall.stock.discard_perishable(_stall.products)
	# Uncooked regular orders go back to storage.
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
	_summary_label.text = "%s\nĐÁNH GIÁ: %d/5 sao\nThu được: %dk   Tiền chợ: -%dk   Lãi: %dk\n%s\nKhách đã phục vụ: %d   Khách bỏ đi: %d\nThừa: %d phần hải sản (trả về kho), %d phần rau (bỏ đi)\n%s%s" % [
		reason, stars, _earned_today, _market_spent, _earned_today - _market_spent, variety_text,
		_served, _left_angry, leftover, wasted_produce, _rating_hint(stars),
		("\n" + "\n".join(order_lines)) if not order_lines.is_empty() else ""]
	_summary_panel.show()
	_next_day_button.grab_focus()


## E: the kitchen / tables first, else talk to whoever stands right there.
func _on_rin_interacted(cell: Vector2i) -> void:
	if _stall.interact(_rin) or _stall.store_at(cell) or _kitchen.interact(cell):
		return
	var spot := _room.grid.to_world(cell)
	for node in get_tree().get_nodes_in_group("talkers"):
		var talker := node as Talker
		if talker and talker.can_talk() and (talker.talk_position().distance_to(spot) <= talk_reach
				or talker.talk_position().distance_to(_rin.position) <= talk_reach):
			talker.talk(_dialogue_box)
			return


func _on_customer_served(price: int, tip: int) -> void:
	_earned_today += price + tip
	_served += 1


func _show_message(text: String, seconds: float = message_seconds) -> void:
	_message_token += 1
	var token := _message_token
	_message_label.text = text
	_message_label.show()
	await get_tree().create_timer(seconds).timeout
	if token == _message_token:
		_message_label.hide()


func _rating_hint(stars: int) -> String:
	if stars >= 4:
		return "Khách khen nức nở, mai sẽ đông khách hơn!"
	if stars <= 2:
		return "Khách chê, mai sẽ vắng hơn..."
	return ""


## Summary closed: the evening is free — upgrade, repair, then sail.
func _on_continue_pressed() -> void:
	_summary_panel.hide()
	var scene := DialogueLibrary.pick(after_shift_cutscenes) as Cutscene
	if scene:
		await _cutscene.play(scene)
	_renovate_button.show()
	_sail_button.show()
	_tutorial.on_evening()


## "Sửa quán": hide people and panels, let RenovationMode take over.
func _open_renovation() -> void:
	_set_room_ui_visible(false)
	_renovation.open()


func _on_renovation_finished(applied: bool) -> void:
	_set_room_ui_visible(true)
	if applied:
		_customers.refresh_upgrades()
		_show_message("Đã sửa quán!")


## People, panels and pinned buttons (hidden while renovating).
func _set_room_ui_visible(on: bool) -> void:
	for node: CanvasItem in [$World/People, $World/Bikes, $World/Markers, $HUD]:
		node.visible = on
	_menu_panel.visible = false
	_sail_button.visible = on and _shift_over
	_renovate_button.visible = on


func _pin_button(text: String, rect: Rect2) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 10)
	button.focus_mode = Control.FOCUS_NONE
	$HUD.add_child(button)
	# Sized once in the tree: before that the minimum size uses the default font.
	button.position = rect.position
	button.size = rect.size
	return button


func _start_next_day() -> void:
	var loss: float = float(GameState.get_upgrade_value(fridge_upgrade)) if fridge_upgrade else 35.0
	GameState.advance_day(loss)
	# Morning messages: maybe a new fish order (shown at sea and in the phone).
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	FishOrders.roll_new_order(rng, fish_catalog)
	SceneRouter.go_to(SEA_SCENE_PATH)
