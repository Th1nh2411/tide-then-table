class_name PartyFactory
extends RefCounted
## Brings parties to the street restaurant during a shift (CustomerManager
## adds them): when the next one comes (walk-in timer scaled by the rating
## and the decor; regulars with a fish order early in the shift, as soon as a
## table is free) and who they are (well-off, a pair, a regular; patience
## scaled by the tuning and the cat).

## Today's ServiceTuning (CustomerManager.tuning).
var tuning: ServiceTuning
## Decor upgrade level (indexes the tuning's decor arrays).
var decor_level: int = 0

var _regulars_to_spawn: Array[Dictionary] = []
var _shift_time: float = 0.0
var _spawn_left: float = 0.0
var _interval_scale: float = 1.0
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


## `visits` = today's regular visits (FishOrders.reserve_for_shift()).
func start(visits: Array[Dictionary]) -> void:
	_interval_scale = tuning.interval_scale_by_rating[clampi(GameState.last_rating, 0, tuning.interval_scale_by_rating.size() - 1)]
	_interval_scale *= by_decor(tuning.decor_interval_scale)
	_regulars_to_spawn = visits.duplicate()
	_shift_time = 0.0
	_spawn_left = tuning.first_spawn_delay


func stop() -> void:
	_regulars_to_spawn.clear()


## Advances the shift clock; the next regular's visit once it's their time
## and a table is free, else {}.
func regular_due(delta: float, seat_free: bool) -> Dictionary:
	_shift_time += delta
	if not _regulars_to_spawn.is_empty() and _shift_time >= tuning.regular_delay and seat_free:
		return _regulars_to_spawn.pop_front()
	return {}


## Ticks the walk-in timer; true when it fires (restarts it).
func walk_in_due(delta: float) -> bool:
	_spawn_left -= delta
	if _spawn_left > 0.0:
		return false
	_spawn_left = _rng.randf_range(tuning.min_spawn_interval, tuning.max_spawn_interval) * _interval_scale
	if is_rush():
		_spawn_left *= tuning.rush_interval_scale
	return true


## Rush hour right now (WaveMark.has_power() only).
func is_rush() -> bool:
	return WaveMark.has_power() and GameState.day >= WaveMark.RUSH_FROM_DAY \
		and _shift_time >= tuning.rush_from and _shift_time < tuning.rush_to


## A new party at one of `free_seats` (`visit` = a regular's visit, or {}
## for a walk-in).
func create(visit: Dictionary, free_seats: Array[int]) -> Customer:
	var customer := Customer.new()
	customer.seat = free_seats[_rng.randi() % free_seats.size()]
	if visit.is_empty():
		customer.rich = _rng.randf() < by_decor(tuning.rich_chance_by_decor)
		if customer.rich:
			customer.patience_seconds *= tuning.rich_patience_scale
		if _rng.randf() < tuning.pair_chance:
			customer.companion = Customer.new()
			customer.companion.leader = customer
			customer.companion.seat = customer.seat
		customer.more_rounds = tuning.max_more_rounds
	else:
		customer.visit = visit
		customer.regular_name = visit["order"]["who"]
		customer.patience_seconds *= tuning.regular_patience_scale
	if PetCat.is_present():
		customer.patience_seconds *= tuning.cat_patience_scale
	return customer


## `table`'s value for the current decor level (1.0 if empty).
func by_decor(table: Array[float]) -> float:
	if table.is_empty():
		return 1.0
	return table[clampi(decor_level, 0, table.size() - 1)]
