class_name ShiftLog
extends RefCounted
## What happened in one restaurant shift, filled by the service code:
## every dish eaten, every table that paid, every party that left.
## Read by DailyChallenges (progress), LifetimeStats (lifetime counters) and,
## later, the end-of-shift scoreboard. Pure data, no nodes.

## Emitted after every record (the challenge card / NEO listen).
signal logged

## One entry per dish eaten:
## {"id": String, "grill": bool, "beer": bool, "price": int, "hot": bool}
var dishes: Array[Dictionary] = []
## One entry per table that paid:
## {"bill": int, "tip": int, "patience": float (0..1 left when served), "regular": bool}
var parties: Array[Dictionary] = []
## Parties that walked out.
var lost: int = 0
## Everything paid this shift (bills + tips + part bills of leavers).
var earned: int = 0


## A dish was eaten. `price` is that line's price (before the table's tip).
func record_dish(dish: DishData, price: int, hot: bool) -> void:
	var beer: bool = dish.instant_serve
	dishes.append({"id": dish.id, "grill": dish.cook_type == DishData.CookType.GRILL and not beer,
		"beer": beer, "price": price, "hot": hot})
	logged.emit()


## A table paid its whole bill (+ tip).
func record_party(bill: int, tip: int, patience_ratio: float, regular: bool = false) -> void:
	parties.append({"bill": bill, "tip": tip, "patience": clampf(patience_ratio, 0.0, 1.0), "regular": regular})
	earned += bill + tip
	logged.emit()


## A table left early; `paid` = what they had already eaten.
func record_lost(paid: int = 0) -> void:
	lost += 1
	earned += paid
	logged.emit()


func parties_served() -> int:
	return parties.size()


func grill_count() -> int:
	return dishes.filter(func(d: Dictionary) -> bool: return bool(d["grill"])).size()


func beer_count() -> int:
	return dishes.filter(func(d: Dictionary) -> bool: return bool(d["beer"])).size()


func hot_count() -> int:
	return dishes.filter(func(d: Dictionary) -> bool: return bool(d["hot"])).size()


func tips_count() -> int:
	return parties.filter(func(p: Dictionary) -> bool: return int(p["tip"]) > 0).size()


func tips_total() -> int:
	var total := 0
	for party in parties:
		total += int(party["tip"])
	return total


## Tables served with more than `min_ratio` of their patience left.
func fast_count(min_ratio: float) -> int:
	return parties.filter(func(p: Dictionary) -> bool: return float(p["patience"]) > min_ratio).size()


## dish id -> how many eaten this shift.
func dish_counts() -> Dictionary:
	var counts: Dictionary = {}
	for dish in dishes:
		counts[dish["id"]] = int(counts.get(dish["id"], 0)) + 1
	return counts
