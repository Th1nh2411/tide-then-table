class_name TableOrder
extends RefCounted
## One dish a table ordered and is still waiting for (a party orders one or
## more; CustomerManager.waiting keeps them oldest first). Bảo, the grill,
## the beer tap, the tickets and the bubbles all work per line; seat,
## patience and the regular's name come from the party's leader.

var dish: DishData
## The regular visit this line is for ({} for a normal dish).
var visit: Dictionary = {}
## The party's leader, a Customer (null in pure tests). Typed as
## StreetPerson: Customer lists its TableOrders, and a two-way class
## reference leaks both scripts at exit.
var party: StreetPerson

var seat: int:
	get:
		return int(party.get("seat")) if party else -1
var patience: float:
	get:
		return float(party.get("patience")) if party else 1.0
var regular_name: String:
	get:
		return str(party.get("regular_name")) if party else ""


func _init(p_dish: DishData = null, p_visit: Dictionary = {}, p_party: StreetPerson = null) -> void:
	dish = p_dish
	visit = p_visit
	party = p_party
