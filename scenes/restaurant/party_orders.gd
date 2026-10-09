class_name PartyOrders
extends RefCounted
## Takes a seated party's orders as TableOrder lines (also kept oldest first
## in `waiting`, the same array as CustomerManager.waiting): a regular's
## order dish, or one dish per guest (sometimes one more, OrderPicker); once
## everything is eaten, maybe another round (often beer).

var picker: OrderPicker
var waiting: Array[TableOrder]
var _rng := RandomNumberGenerator.new()


func _init(p_picker: OrderPicker, p_waiting: Array[TableOrder]) -> void:
	picker = p_picker
	waiting = p_waiting
	_rng.randomize()


## Adds the first order's lines; false if nothing could be ordered.
func take_first(customer: Customer, tuning: ServiceTuning) -> bool:
	if not customer.visit.is_empty():
		_add_line(customer, customer.visit["dish"], customer.visit)
		return true
	for i in picker.first_order_size(2 if customer.companion else 1, tuning.extra_dish_chance, tuning.max_lines):
		var dish := picker.pick(tuning.side_order_chance, waiting)
		if dish:
			_add_line(customer, dish)
	return not customer.orders.is_empty()


## Maybe one more dish after everything was eaten; true if one was ordered.
func take_another_round(customer: Customer, tuning: ServiceTuning) -> bool:
	if customer.more_rounds <= 0 or _rng.randf() >= tuning.more_round_chance:
		return false
	customer.more_rounds -= 1
	var dish := picker.pick(tuning.round_side_chance, waiting)
	if dish == null:
		return false
	_add_line(customer, dish)
	return true


func _add_line(customer: Customer, dish: DishData, visit: Dictionary = {}) -> void:
	var order := TableOrder.new(dish, visit, customer)
	customer.add_order(order)
	waiting.append(order)
