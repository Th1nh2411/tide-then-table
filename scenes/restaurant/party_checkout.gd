class_name PartyCheckout
extends RefCounted
## Settling up with a party that leaves (CustomerManager adds the money and
## emits the signals): its bill (TableBill: every plate eaten + tip), the
## regulars' fish orders it completes, and the lines dropped when it leaves
## before everything came.


## Leaving early: lines still waiting are dropped; plates it already had
## (queued + the current one) count as eaten.
static func drop_unserved(customer: Customer, waiting: Array[TableOrder]) -> void:
	for order in customer.orders:
		waiting.erase(order)
	customer.orders.clear()
	customer.eaten.append_array(customer.queued)
	if customer.plate:
		customer.eaten.append(customer.plate)


## Price (x) and tip (y) for every plate eaten; tip only if `tip_ok`, the
## party is still patient enough, and never for regulars.
static func bill(customer: Customer, variety: float, tuning: ServiceTuning, tip_ok: bool, tip_bonus: float) -> Vector2i:
	var price := TableBill.total(customer.eaten, variety, tuning.rich_price_scale if customer.rich else 1.0)
	var tip := 0
	if tip_ok and customer.regular_name.is_empty():
		tip = TableBill.tip(price, customer.patience, tuning.tip_patience_threshold, tuning.tip_ratio + tip_bonus)
	return Vector2i(price, tip)


## Completes the fish order of each regular's plate eaten; their prices.
static func complete_regular_orders(customer: Customer) -> Array[int]:
	var prices: Array[int] = []
	for plate in customer.eaten:
		if not plate.visit.is_empty():
			FishOrders.complete(plate.visit["order"])
			prices.append(TableBill.plate_price(plate, 1.0, 1.0))
	return prices
