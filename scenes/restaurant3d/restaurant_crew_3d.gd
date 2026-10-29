class_name RestaurantCrew3D
extends RefCounted
## Bảo (cooks non-grilled dishes) and the hired helpers (carry plates, clean tables).
## Reads and writes the host's `orders`, `dirty_tables`; serves/cleans through the host.

const L = preload("res://scenes/restaurant3d/restaurant_layout_3d.gd")

var host: Node3D
var workers: Array[Dictionary] = []
var bao_table: int = -1
var bao_seconds: float = 0.0

func _init(owner: Node3D) -> void:
	host = owner

func sync_staff() -> void:
	for worker in workers:
		var table: int = worker["table"]
		if table >= 0 and not host.orders[table].is_empty():
			host.orders[table]["staff_claimed"] = false
		(worker["node"] as Node3D).queue_free()
	workers.clear()
	for person in host.staff_roster.hired():
		var variant: String = "vy_sau" if GameState.has_flag("vy_warmed") else "vy"
		var node := PersonRig3D.build(host, variant if person.id == "vy" else "staff")
		node.position = Vector3(3.3 + workers.size() * 0.7, 0, -0.5)
		workers.append({"data": person, "node": node, "table": -1, "picked": false})
	if host.shift_running:
		dispatch_ready()

## Hands each cooked, unclaimed order to an idle helper.
func dispatch_ready() -> void:
	var orders: Array[Dictionary] = host.orders
	for i in range(orders.size()):
		if orders[i].is_empty() or str(orders[i].get("phase", "waiting")) != "waiting" or not bool(orders[i].get("cooked", false)) or bool(orders[i].get("staff_claimed", false)) or host.carrying_table == i:
			continue
		for worker in workers:
			if int(worker["table"]) == -1:
				worker["table"] = i
				orders[i]["staff_claimed"] = true
				break

func move_staff(delta: float) -> void:
	for worker in workers:
		var node: Node3D = worker["node"]
		var table: int = worker["table"]
		var data: StaffData = worker["data"]
		if data.id == "vy":
			node.set_variant("vy_sau" if GameState.has_flag("vy_warmed") else "vy")
		node.set_carrying(bool(worker.get("picked", false)))
		if table < 0:
			var dirty: int = host.dirty_tables.find(true)
			if dirty >= 0:
				var clean_target: Vector3 = L.TABLES[dirty] + Vector3(0, 0, 1.1)
				StaffPathing3D.step(node, L.TABLES, clean_target, delta * 3.0)
				if node.position.distance_to(clean_target) < 0.06:
					host._clean_table(dirty)
				continue
			var home := Vector3(3.3 + workers.find(worker) * 0.7, 0, -0.5)
			StaffPathing3D.step(node, L.TABLES, home, delta * 2.5)
			continue
		if host.orders[table].is_empty():
			worker["picked"] = false
			worker["table"] = -1
			continue
		var picked: bool = bool(worker.get("picked", false))
		var target: Vector3 = L.TABLES[table] + Vector3(0, 0, 1.2) if picked else L.PASS_POSITION + Vector3(0, 0, 1.0)
		var person: StaffData = worker["data"]
		StaffPathing3D.step(node, L.TABLES, target, delta * person.walk_speed / 23.0)
		if node.position.distance_to(target) < 0.05:
			if not picked:
				worker["picked"] = true
			else:
				host._serve(table)
				worker["table"] = -1
				worker["picked"] = false

func tick_bao(delta: float) -> void:
	var orders: Array[Dictionary] = host.orders
	if bao_table >= 0:
		if orders[bao_table].is_empty():
			bao_table = -1
		else:
			bao_seconds -= delta
			host.bao_model.rotation.y = sin(host.step_clock * 7.0) * 0.08
			if bao_seconds <= 0.0:
				var table: int = bao_table
				bao_table = -1
				orders[table]["cooked"] = true
				var visit: Dictionary = orders[table].get("visit", {})
				if not visit.is_empty():
					visit["cooked"] = true
				host._show_note("Bảo: Món bàn %d xong rồi Rin!" % (table + 1))
				dispatch_ready()
	if bao_table < 0:
		host.bao_label.text = "Bảo • bếp"
		for i: int in range(orders.size()):
			if orders[i].is_empty() or bool(orders[i].get("cooked", false)):
				continue
			var dish: DishData = orders[i]["dish"]
			if ChefBao.cooks(dish):
				bao_table = i
				bao_seconds = maxf(1.8, 5.0 - DishBook.kitchen_level())
				host.bao_label.text = "Bảo: " + dish.display_name
				break
