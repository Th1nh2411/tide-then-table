class_name RestaurantShift3D
extends RefCounted
## The 3D restaurant's shift clock: open the shift, tick it (clock, Bảo,
## guests arriving, eating and running out of patience), close early (T),
## and leave by a street end: the dock (night at sea) or home (sleep); the
## bedroom judges the night (LoopCalendar). Balance: ServiceTuning by day.

const SEA_SCENE := "res://scenes/sea3d/sea_scene_3d.tscn"
const BEDROOM_SCENE := "res://scenes/home3d/bedroom_scene_3d.tscn"
## Short shifts: one day of the loop should take a few minutes.
const SHIFT_SECONDS := 120.0
const TUNINGS := [
	preload("res://data/restaurant/service_day1.tres"),
	preload("res://data/restaurant/service_day2.tres"),
	preload("res://data/restaurant/service_day3.tres"),
	preload("res://data/restaurant/service_day5.tres"),
]

var host: Node3D


func _init(owner: Node3D) -> void:
	host = owner


## The latest ServiceTuning whose from_day has come.
static func pick_tuning() -> ServiceTuning:
	var current: ServiceTuning = TUNINGS[0]
	for stage: ServiceTuning in TUNINGS:
		if stage.from_day <= GameState.day:
			current = stage
	return current


## Seconds to the next guest: decor and yesterday's rating bring them sooner.
func next_spawn_interval() -> float:
	var tuning: ServiceTuning = host.tuning
	var decor_level := GameState.get_upgrade_level("decor")
	var decor_scale: float = tuning.decor_interval_scale[clampi(decor_level, 0, tuning.decor_interval_scale.size() - 1)]
	var rating_scale: float = tuning.interval_scale_by_rating[clampi(GameState.last_rating, 0, tuning.interval_scale_by_rating.size() - 1)]
	return host.rng.randf_range(tuning.min_spawn_interval, tuning.max_spawn_interval) * decor_scale * rating_scale \
		* RestaurantSocial3D.spawn_scale()


func open_shift() -> void:
	if host.shift_running or host.shift_over or not has_stock():
		return
	host.opening_variety = host.plan.variety_count()
	host.planning_panel.hide()
	host.shift_running = true
	host.seconds_left = SHIFT_SECONDS
	host.spawn_clock = host.tuning.first_spawn_delay
	host.goals.start_shift()
	if Guide.once("shift_h2"):
		host._show_note("Rin: Bảo nấu, mình bưng. Bia lấy ở thùng. T: đóng sớm.")


func tick(delta: float) -> void:
	host.seconds_left = maxf(host.seconds_left - delta, 0.0)
	DayClock.set_progress(1.0 - host.seconds_left / SHIFT_SECONDS, DayClock.shop_open_hour, DayClock.shop_close_hour)
	host._tick_bao(delta)
	host._sync_food_visuals()
	host.spawn_clock -= delta
	if host.spawn_clock <= 0.0 and host.seconds_left > 0.0:
		host._spawn_order()
		host.spawn_clock = next_spawn_interval()
	var orders: Array[Dictionary] = host.orders
	for i in range(orders.size()):
		if orders[i].is_empty():
			continue
		if str(orders[i].get("phase", "waiting")) == "eating":
			orders[i]["meal_left"] = float(orders[i]["meal_left"]) - delta
			if float(orders[i]["meal_left"]) <= 0.0:
				host._finish_meal(i)
			continue
		orders[i]["patience"] = float(orders[i]["patience"]) - delta
		if float(orders[i]["patience"]) <= 0.0:
			host._lose_order(i)
	if (host.seconds_left <= 0.0 or not has_stock()) and orders.all(func(order: Dictionary) -> bool: return order.is_empty()):
		host._end_shift()


func close_early() -> void:
	if not host.shift_running or host.seconds_left <= 0.0:
		return
	host.seconds_left = 0.0
	host._show_note("Rin: đóng cửa, phục vụ nốt khách đang ngồi.")


## The fixed menu never runs out (RestaurantService3D.FIXED_MENU).
func has_stock() -> bool:
	return true


## Skip the shift (leave() returns the planned fish and releases today's regulars).
func sail_without_shift() -> void:
	FishOrders.expire_after_shift(host.fish_catalog)
	sail()


## The dock end of the street: tonight at sea (the day turns in the bedroom).
func sail() -> void:
	await leave(true)


## The home end of the street: sleep, no night at sea.
func go_home() -> void:
	await leave(false)


func leave(to_dock: bool) -> void:
	if host.sailing or host.shift_running:
		return
	host.sailing = true
	if not host.shift_over:
		host.plan.clear(GameState.storage)
		for visit: Dictionary in host.regular_visits:
			FishOrders.release(visit)
	host.bag.store(host.market_stock, host.menu.dishes)
	GameState.resume_at = "home"
	if to_dock:
		SceneRouter.go_to(SEA_SCENE)
	else:
		LoopCalendar.choose(false)
		SceneRouter.go_to(BEDROOM_SCENE)
