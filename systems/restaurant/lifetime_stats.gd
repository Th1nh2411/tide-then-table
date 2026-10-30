class_name LifetimeStats
extends RefCounted
## Lifetime restaurant counters in GameState.stats (saved), added up from
## each ShiftLog at closing. Achievements read them. Pure logic.
## Keys (all int): served_total (tables paid), lost_total, dishes_total,
## earned_total, grill_total, beer_total, hot_total, tips_total (k),
## fast_total, shifts_total, five_star_days, perfect_days, best_day_earned,
## dish_kinds (= dishes_sold.size()), staff_max (most helpers hired at once),
## challenges_done; plus dishes_sold {dish id: int}.

const INT_KEYS: Array[String] = ["served_total", "lost_total", "dishes_total", "earned_total",
	"grill_total", "beer_total", "hot_total", "tips_total", "fast_total", "shifts_total",
	"five_star_days", "perfect_days", "best_day_earned", "dish_kinds", "staff_max", "challenges_done"]
## A perfect day: nobody left and at least this many tables paid.
const PERFECT_MIN_PARTIES: int = 3
## "Served fast" for the lifetime counter (same as the daily challenge).
const FAST_RATIO: float = 0.5


static func value(stats: Dictionary, key: String) -> int:
	return int(stats.get(key, 0))


static func add(stats: Dictionary, key: String, amount: int) -> void:
	stats[key] = value(stats, key) + amount


## Adds one closed shift. `stars` = the day's rating, `hired` = helpers on staff.
static func apply(stats: Dictionary, shift: ShiftLog, stars: int, hired: int) -> void:
	add(stats, "served_total", shift.parties_served())
	add(stats, "lost_total", shift.lost)
	add(stats, "dishes_total", shift.dishes.size())
	add(stats, "earned_total", shift.earned)
	add(stats, "grill_total", shift.grill_count())
	add(stats, "beer_total", shift.beer_count())
	add(stats, "hot_total", shift.hot_count())
	add(stats, "tips_total", shift.tips_total())
	add(stats, "fast_total", shift.fast_count(FAST_RATIO))
	add(stats, "shifts_total", 1)
	if stars >= 5:
		add(stats, "five_star_days", 1)
	if shift.lost == 0 and shift.parties_served() >= PERFECT_MIN_PARTIES:
		add(stats, "perfect_days", 1)
	stats["best_day_earned"] = maxi(value(stats, "best_day_earned"), shift.earned)
	stats["staff_max"] = maxi(value(stats, "staff_max"), hired)
	var sold: Dictionary = stats.get("dishes_sold", {})
	var counts := shift.dish_counts()
	for id: String in counts:
		sold[id] = int(sold.get(id, 0)) + int(counts[id])
	stats["dishes_sold"] = sold
	stats["dish_kinds"] = sold.size()


## Clean copy of saved stats (JSON floats -> ints, junk dropped).
static func from_save(data: Variant) -> Dictionary:
	var stats: Dictionary = {}
	if not data is Dictionary:
		return stats
	for key: String in INT_KEYS:
		var number: Variant = data.get(key)
		if number is int or number is float:
			stats[key] = maxi(int(number), 0)
	var sold: Variant = data.get("dishes_sold")
	if sold is Dictionary:
		var clean: Dictionary = {}
		for id: Variant in sold:
			if id is String and (sold[id] is int or sold[id] is float):
				clean[id] = maxi(int(sold[id]), 0)
		stats["dishes_sold"] = clean
	return stats
