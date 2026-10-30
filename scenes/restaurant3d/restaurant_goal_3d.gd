class_name RestaurantGoal3D
extends RefCounted
## Which thing Rin should go to next, for the soft pulse highlight (no text).
## Pure: reads the host. Returns the node to pulse, or null.
## Order: plate in hand -> its table; plate ready -> plate bench; grill dish
## waiting -> grill; beer waiting -> keg; dirty table; before the shift -> menu board.


static func target(host: Node3D) -> Node3D:
	if not host.shift_running:
		if host.shift_over or host.plan == null or host.plan.total_portions() > 0:
			return null
		return host.get_node_or_null("WorldMenuBoard") as Node3D
	var carrying: int = host.carrying_table
	if carrying >= 0:
		return _table(host, carrying)
	var ready: Array[Node3D] = host.ready_plates
	for plate in ready:
		if plate.visible:
			return host.get_node_or_null("Batch_plate_bench") as Node3D
	var grill_waiting := false
	var beer_waiting := false
	var orders: Array[Dictionary] = host.orders
	for order in orders:
		if order.is_empty() or bool(order.get("cooked", false)) or str(order.get("phase", "waiting")) != "waiting":
			continue
		var dish: DishData = order.get("dish") as DishData
		if dish == null:
			continue
		if dish.instant_serve:
			beer_waiting = true
		elif not ChefBao.cooks(dish):
			grill_waiting = true
	if grill_waiting:
		return host.get_node_or_null("Batch_charcoal_grill") as Node3D
	if beer_waiting:
		return host.get_node_or_null("Batch_beer_keg") as Node3D
	var dirty: Array[bool] = host.dirty_tables
	for i in range(dirty.size()):
		if dirty[i]:
			return _table(host, i)
	return null


static func _table(host: Node3D, index: int) -> Node3D:
	return host.get_node_or_null("DiningTable_%d" % index) as Node3D
