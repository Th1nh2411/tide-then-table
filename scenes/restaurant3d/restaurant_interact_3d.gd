class_name RestaurantInteract3D
extends RefCounted
## What E does in the 3D restaurant, by where Rin stands: Cô Năm
## (she talks, RestaurantRoles3D), Vy (looked at, hands free: VyTalk3D),
## Bảo / anh Út (looked at, hands free: RestaurantRoles3D), tables (serve
## the carried plate / clean), the plate table and the beer keg (a tower
## straight into Rin's hands).

const L = preload("res://scenes/restaurant3d/restaurant_layout_3d.gd")

var host: Node3D


func _init(owner: Node3D) -> void:
	host = owner


func interact() -> void:
	var at: Vector3 = host.player.position
	var roles := RestaurantRoles3D.of(host)
	if at.distance_to(L.COUNTER_POSITION) < 2.1:
		if roles:
			roles.co_nam_say()  # rằm, tonight's omen, then the day's gossip
		return
	if not host.shift_running:
		if roles and host.carrying_table < 0:
			roles.talk(at)
		return
	if host.carrying_table >= 0:
		var table: int = host.carrying_table
		if at.distance_to(L.TABLES[table]) < 2.0:
			host._serve(table)
		else:
			host._show_note("Đem món tới bàn %d." % (table + 1))
		return
	for i: int in range(host.dirty_tables.size()):
		if host.dirty_tables[i] and at.distance_to(L.TABLES[i]) < 2.0:
			host._clean_table(i)
			return
	var at_bench: bool = at.distance_to(L.PASS_POSITION) < 1.35
	if at_bench and host.service.next_ready() >= 0:
		host._pickup_ready()
		return
	var vy: VyStaff3D = host.vy
	if vy and vy.talk.can_talk(at, host.demo_camera):
		host._show_note(vy.talk.say())
		return
	if roles and roles.talk(at):
		return
	if at_bench:
		host._pickup_ready()
		return
	_cook_here(at)


## At the beer keg: the oldest waiting beer goes straight into Rin's hands.
func _cook_here(at: Vector3) -> void:
	if at.distance_to(L.BEER_POSITION) >= 1.7:
		return
	for i: int in range(host.orders.size()):
		var order: Dictionary = host.orders[i]
		if order.is_empty() or bool(order.get("cooked", false)):
			continue
		var dish: DishData = order["dish"]
		if dish.instant_serve:
			Sfx.play("clink")
			beer_poured(i)
			return
	host._show_note("Chưa bàn nào gọi bia.")


## A beer tower for `table`: into Rin's hands if they are free.
func beer_poured(table: int) -> void:
	if table < 0 or host.orders[table].is_empty():
		return
	host.orders[table]["cooked"] = true
	if host.carrying_table < 0:
		host.carrying_table = table
		host._show_note("Đem %s tới bàn %d." % [host.orders[table]["dish"].display_name, table + 1])
	else:
		host._show_note("Bia bàn %d đã xong!" % (table + 1))
