class_name RestaurantShift3D
extends RefCounted
## The 3D restaurant's shift clock: open the shift, tick it (clock, Bảo,
## guests arriving, eating and running out of patience) and close early (T).
## Balance: ServiceTuning by day.

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


## Seconds to the next guest: yesterday's rating brings them sooner.
func next_spawn_interval() -> float:
	var tuning: ServiceTuning = host.tuning
	var rating_scale: float = tuning.interval_scale_by_rating[clampi(GameState.last_rating, 0, tuning.interval_scale_by_rating.size() - 1)]
	return host.rng.randf_range(tuning.min_spawn_interval, tuning.max_spawn_interval) * rating_scale


func open_shift() -> void:
	if host.shift_running or host.shift_over:
		return
	host.shift_running = true
	host.seconds_left = SHIFT_SECONDS
	host.spawn_clock = host.tuning.first_spawn_delay
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
	if host.seconds_left <= 0.0 and orders.all(func(order: Dictionary) -> bool: return order.is_empty()):
		host._end_shift()


func close_early() -> void:
	if not host.shift_running or host.seconds_left <= 0.0:
		return
	host.seconds_left = 0.0
	host._show_note("Rin: đóng cửa, phục vụ nốt khách đang ngồi.")

