extends Control
## Restaurant screen: a sidewalk seafood spot seen top-down (StreetRoom).
## Day flow: arrival story scene (ArrivalCutscenes) -> plan the menu (click
## the LED sign, MenuSetupPanel) -> open -> serve until the shift ends (or
## close early; guests inside still eat) -> summary (ShiftReport) -> evening:
## "Sửa quán" (RenovationMode) and "Ra khơi" (next night). Bảo cooks
## (ChefBao), Rin serves / grills / pours (KitchenStation), customers come
## and pay (CustomerManager), staff help (StaffCrew), the grocery is next door
## (MarketStall + MarketPanel). First-time pointers: RestaurantGuide; quests:
## QuestTracker; debug keys: RestaurantDebug.

## Real seconds for the whole shift (15:00 -> 24:00 on the displayed clock).
@export var base_shift_seconds: float = 180.0
@export var menu: DishCatalog
@export var fish_catalog: FishCatalog
## How many different dishes the menu can hold, by kitchen upgrade level.
@export var menu_slots_by_kitchen: Array[int] = [3, 4, 5]
## Price multiplier by number of distinct dishes on the menu (index = count;
## higher counts use the last entry). Customers get bored of a tiny menu.
@export var variety_multipliers: Array[float] = [0.8, 0.8, 0.9, 1.0, 1.05, 1.1]
@export var message_seconds: float = 1.5
## Fridge upgrade: its value is the freshness lost overnight.
@export var fridge_upgrade: UpgradeData
## Cutscenes that can play after the summary (first eligible one, once).
@export var after_shift_cutscenes: Array[Cutscene] = []
## Cutscenes that can play on arriving, before the menu is planned (opening
## day, beer, Vy...): highest priority eligible one, once.
@export var arrival_cutscenes: Array[Cutscene] = []
## Everyone who could be hired, and the job ads.
@export var staff_catalog: StaffCatalog
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
var _evening: RestaurantEvening
var _dialogue_box: DialogueBox
var _guide: RestaurantGuide
var _market_panel: MarketPanel
var _crew: StaffCrew

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
	_evening = RestaurantEvening.new()
	_evening.hud = $HUD
	_evening.renovation = _renovation
	_evening.world_layers = [$World/People, $World/Bikes, $World/Markers, $HUD]
	_evening.menu_panel = _menu_panel
	_evening.fridge_upgrade = fridge_upgrade
	_evening.fish_catalog = fish_catalog
	_evening.shift_over = is_shift_over
	_evening.message_requested.connect(_show_message)
	_evening.renovated.connect(_on_renovated)
	add_child(_evening)
	_room.kitchen_level = GameState.get_upgrade_level(_renovation.kitchen_upgrade.id)
	_room.fridge_level = GameState.get_upgrade_level(_renovation.fridge_upgrade.id)
	# The minigame pops over the road below the kitchen (middle of the pavement).
	var cooking_panel := $CookingOverlay/Panel as Control
	cooking_panel.offset_left = 205.0
	cooking_panel.offset_right = 435.0
	cooking_panel.offset_top = 212.0
	cooking_panel.offset_bottom = 328.0
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
	_crew = StaffCrew.new()
	_crew.catalog = staff_catalog
	_crew.room = _room
	_crew.customers = _customers
	_crew.people_layer = $World/People
	_crew.message_requested.connect(_show_message.bind(3.0))
	add_child(_crew)
	_rin.interacted.connect(_on_rin_interacted)
	_dialogue_box = DialogueBox.new()
	add_child(_dialogue_box)
	_customers.regular_served.connect(func(who: String, price: int) -> void:
		GameState.set_flag("regular_served_once")  # the regular's tea after the shift
		_show_message("%s khen ngon, trả %dk!" % [who, price], 2.5))
	_plan = MenuPlan.new(_menu_slots())
	_kitchen.setup(_plan)
	_chef.setup(_plan)
	_menu_panel.setup(_plan, menu, fish_catalog, variety_multipliers)
	_menu_panel.confirmed.connect(_open_shop)
	_menu_panel.hide()  # opened by clicking the LED sign (MenuBoard)
	_time_left = get_shift_seconds()
	_add_guide()
	var tracker := QuestTracker.new()
	tracker.catalog = fish_catalog
	tracker.origin = Vector2(4, 26)  # under the order tickets
	add_child(tracker)
	_cutscene.hidden_nodes.append(tracker)
	var debug := RestaurantDebug.new()
	debug.menu_panel = _menu_panel
	debug.plan = _plan
	debug.fish_catalog = fish_catalog
	debug.stall = _stall
	debug.message_requested.connect(_show_message)
	add_child(debug)
	_play_arrival_cutscene.call_deferred()


## First-time pointers (RestaurantGuide).
func _add_guide() -> void:
	_guide = RestaurantGuide.new()
	_guide.room = _room
	_guide.rin = _rin
	_guide.customers = _customers
	_guide.kitchen = _kitchen
	_guide.stall = _stall
	_guide.board = _board
	_guide.menu_panel = _menu_panel
	_guide.market_panel = _market_panel
	_guide.crew = _crew
	_guide.renovation = _renovation
	_guide.open_button = _menu_panel.get_open_button()
	_guide.renovate_button = _evening.renovate_button
	_guide.sail_button = _evening.sail_button
	_guide.serving = is_serving
	_guide.shift_over = is_shift_over
	add_child(_guide)


func is_serving() -> bool:
	return _shift_running or _closing


func is_shift_over() -> bool:
	return _shift_over


func _play_arrival_cutscene() -> void:
	await get_tree().process_frame  # let the router's fade-in start first
	var message: String = await ArrivalCutscenes.play(_cutscene, arrival_cutscenes, _crew.roster)
	if message:
		_show_message(message, 2.5)


func _menu_slots() -> int:
	var level := GameState.get_upgrade_level(_renovation.kitchen_upgrade.id)
	return menu_slots_by_kitchen[clampi(level, 0, menu_slots_by_kitchen.size() - 1)]


func get_shift_seconds() -> float:
	return base_shift_seconds


func _open_shop() -> void:
	_menu_panel.hide()
	_variety_count = _plan.variety_count()
	_variety_multiplier = MenuPlan.variety_multiplier(_variety_count, variety_multipliers)
	_shift_running = true
	_close_early_button.show()
	_evening.renovate_button.hide()
	_crew.start_shift()
	_customers.start_shift(_plan, _variety_multiplier, _regular_visits)
	_show_message("Quán mở cửa!")


func _process(delta: float) -> void:
	# Rin walks freely whenever no panel covers the room.
	_rin.active = not ($CookingOverlay.is_running() or _kitchen.busy or _renovation.visible
		or _menu_panel.visible or _summary_panel.visible or _market_panel.visible)
	_rin.kitchen_open = _shift_running or _closing
	_board.clickable = not _shift_running and not _shift_over and not _closing and _rin.active
	_chef.serving = _rin.kitchen_open
	# Customers don't lose patience while a first-time pointer is teaching.
	Customer.patience_paused = _guide != null and _guide.is_showing()
	_crew.serving = _rin.kitchen_open
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
	# Uncooked regular orders go back to storage.
	for visit in _customers.uncooked_regular_visits():
		FishOrders.release(visit)
	var order_lines := FishOrders.expire_after_shift(fish_catalog)
	var wages := _crew.pay_wages()
	_shift_over = true
	var stars := DayRating.stars(_served, _left_angry, _variety_multiplier < 1.0)
	GameState.last_rating = stars
	GameState.add_day_record({"day": GameState.day, "earned": _earned_today, "market": _market_spent,
		"rating": stars, "served": _served, "left": _left_angry, "wages": wages})
	_summary_label.text = ShiftReport.text({"reason": reason, "stars": stars, "earned": _earned_today,
		"market": _market_spent, "wages": wages, "served": _served, "left": _left_angry,
		"variety": _variety_multiplier, "leftover": leftover}, order_lines)
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


## Summary closed: the evening is free — upgrade, repair, then sail.
func _on_continue_pressed() -> void:
	_summary_panel.hide()
	var scene := DialogueLibrary.pick(after_shift_cutscenes) as Cutscene
	if scene:
		await _cutscene.play(scene)
	_evening.show_evening()


func _on_renovated() -> void:
	_customers.refresh_upgrades()
	_plan.slots = _menu_slots()  # a better kitchen holds more dishes


func _exit_tree() -> void:
	Customer.patience_paused = false
