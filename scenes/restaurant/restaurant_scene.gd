extends Control
## Restaurant screen: a sidewalk seafood spot seen top-down (StreetRoom).
## Day flow: arrival story scene (ArrivalCutscenes) -> plan the menu (click
## the LED sign, MenuSetupPanel) -> open -> serve until the shift ends (or
## close early; guests inside still eat) -> summary (ShiftReport) -> evening:
## "Sửa quán" (RenovationMode) and "Ra khơi" (next night). Bảo cooks
## (ChefBao), Rin serves / grills / pours (KitchenStation), customers come
## and pay (CustomerManager), staff help (StaffCrew), the grocery is next door
## (MarketStall + MarketPanel). First-time pointers: RestaurantGuide; quests:
## QuestTracker + Nhịp Sóng + debug keys: RestaurantTools; the day's books
## and closing: ShiftCloser.

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
## Nhịp Sóng in the restaurant: real seconds the street stays slowed.
@export var wave_seconds: float = 4.0
## How close Rin must be to someone to talk (px).
@export var talk_reach: float = 22.0
## Rin notices closing time when this much of the shift is left.
@export var late_fraction: float = 0.15

var _plan: MenuPlan
var _time_left: float = 0.0
var _shift_running: bool = false
var _shift_over: bool = false
## Closed to new customers, still serving the ones inside.
var _closing: bool = false
var _sold_out_announced: bool = false
## Regulars coming today (FishOrders.reserve_for_shift).
var _regular_visits: Array[Dictionary] = []
var _evening: RestaurantEvening
var _dialogue_box: DialogueBox
var _guide: RestaurantGuide
var _market_panel: MarketPanel
var _crew: StaffCrew
var _rush_shown: bool = false
var _late_said: bool = false
var _speech: SpeechLine
var _closer: ShiftCloser

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
	DailyTrend.ensure(null, menu)  # before the menu panel shows the HOT dish
	_summary_panel.hide()
	_message_label.hide()
	Sfx.ambience("street")
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
	_crew = StaffCrew.new()
	_crew.catalog = staff_catalog
	_crew.room = _room
	_crew.customers = _customers
	_crew.people_layer = $World/People
	_crew.message_requested.connect(_show_message.bind(3.0))
	add_child(_crew)
	_closer = ShiftCloser.new()
	_closer.customers = _customers
	_closer.stall = _stall
	_closer.market_panel = _market_panel
	_closer.crew = _crew
	_closer.chef = _chef
	_closer.rin = _rin
	_closer.fish_catalog = fish_catalog
	_closer.message_requested.connect(_show_message)
	add_child(_closer)
	_rin.interacted.connect(_on_rin_interacted)
	_dialogue_box = DialogueBox.new()
	add_child(_dialogue_box)
	_speech = SpeechLine.new()
	_speech.anchors = {"Rin": _head_of.bind(_rin), "Bảo": _head_of.bind(_chef),
		_stall.seller_name: _head_of.bind(_stall.seller)}
	$HUD.add_child(_speech)
	_customers.regular_served.connect(func(who: String, price: int) -> void:
		GameState.set_flag("regular_served_once")  # the regular's tea after the shift
		_show_message("%s khen ngon, trả %dk. Vui ghê!" % [who, price], 2.5))
	_plan = MenuPlan.new(_menu_slots())
	_plan.kitchen_level = DishBook.kitchen_level()
	_kitchen.setup(_plan)
	_chef.setup(_plan)
	_menu_panel.setup(_plan, menu, fish_catalog, variety_multipliers)
	_menu_panel.confirmed.connect(_open_shop)
	_menu_panel.hide()  # opened by clicking the LED sign (MenuBoard)
	_time_left = get_shift_seconds()
	_add_guide()
	var tools := RestaurantTools.new()
	tools.cutscene = _cutscene
	tools.cutscenes.assign(arrival_cutscenes + after_shift_cutscenes)
	tools.menu_panel = _menu_panel
	tools.plan = _plan
	tools.fish_catalog = fish_catalog
	tools.stall = _stall
	tools.wave_seconds = wave_seconds
	tools.wave_allowed = _wave_allowed
	tools.ripple_origin = _rin_screen_position
	tools.message_requested.connect(_show_message)
	add_child(tools)
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
	DailyTrend.ensure(null, menu)  # a save resumed here may have none yet
	var trend := DailyTrend.announcement(menu)
	if trend != "":
		_show_message(trend, 4.0)
	if message:
		_show_message(message, 2.5)


func _menu_slots() -> int:
	var level := GameState.get_upgrade_level(_renovation.kitchen_upgrade.id)
	return menu_slots_by_kitchen[clampi(level, 0, menu_slots_by_kitchen.size() - 1)]


func get_shift_seconds() -> float:
	return base_shift_seconds


func _open_shop() -> void:
	_menu_panel.hide()
	_closer.variety_multiplier = MenuPlan.variety_multiplier(_plan.variety_count(), variety_multipliers)
	_shift_running = true
	_close_early_button.show()
	_evening.renovate_button.hide()
	_crew.start_shift()
	_customers.start_shift(_plan, _closer.variety_multiplier, _regular_visits)
	_show_message("Mở quán thôi!")


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
	if _customers.is_rush() != _rush_shown:
		_rush_shown = _customers.is_rush()
		if _rush_shown:
			_show_message("Khách tới dồn dập quá!", 2.0)
			if Guide.once("rush"):
				_show_message("NEO: Lượng khách tăng đột biến. Gợi ý: phím C, Nhịp Sóng.", 3.5)
			Sfx.play("pop")
	if _shift_running:
		_time_left = maxf(_time_left - delta, 0.0)
		if not _late_said and _time_left <= get_shift_seconds() * late_fraction:
			_late_said = true
			_show_message("NEO: Còn ít phút nữa là tới giờ đóng quán.", 3.0)
		if _time_left <= 0.0:
			_end_shift("Hết giờ bán!")
		elif _plan.is_sold_out() and not _sold_out_announced:
			_sold_out_announced = true
			_show_message("Hết sạch hải sản rồi, giờ chỉ còn rau với bia thôi...")
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
		_show_message("%s Lo nốt mấy bàn còn lại thôi." % reason, 3.0)
	# Everyone inside gets served and eats (or runs out of patience) first.
	while not _customers.is_idle():
		await get_tree().process_frame
	_closing = false
	var cooking: CookingOverlay = $CookingOverlay
	# Walking to the grill happens before its overlay opens. Let that action
	# (or table cleaning) finish before clearing the kitchen and showing totals.
	while _kitchen.busy or cooking.is_running():
		await get_tree().process_frame
	_shift_over = true
	_summary_label.text = _closer.close(reason, _plan)
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


## Said by Rin (or "Bảo: ..." / "Cô Năm: ...") in a speech bubble.
func _show_message(text: String, seconds: float = message_seconds) -> void:
	_speech.say(text, maxf(seconds, 1.5 + text.length() * 0.04))


func _head_of(person: Node2D) -> Vector2:
	return person.get_global_transform_with_canvas().origin + Vector2(0, -40)


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


func _wave_allowed() -> bool:
	return _shift_running


func _rin_screen_position() -> Vector2:
	return _rin.get_global_transform_with_canvas().origin + Vector2(0, -16)
