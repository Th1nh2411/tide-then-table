class_name TableOrder
extends RefCounted
## One dish a table ordered and is still waiting for (a party orders one or
## more; CustomerManager.waiting keeps them oldest first). Bảo, the grill,
## the beer tap, the tickets and the bubbles all work per line; seat,
## patience and the regular's name come from the party's leader.

var dish: DishData
## The regular visit this line is for ({} for a normal dish).
var visit: Dictionary = {}
## The party's leader (null in pure tests).
var party: Customer

var seat: int:
	get:
		return party.seat if party else -1
var patience: float:
	get:
		return party.patience if party else 1.0
var regular_name: String:
	get:
		return party.regular_name if party else ""


func _init(p_dish: DishData = null, p_visit: Dictionary = {}, p_party: Customer = null) -> void:
	dish = p_dish
	visit = p_visit
	party = p_party
