class_name RestaurantInteract3D
extends RefCounted
## What E does in the 3D restaurant, by where Rin stands: menu board, the
## cat, the fridge (store the market bag), Cô Năm's counter, tables (serve
## the carried plate / clean), the plate table, the grill and the beer tap
## (CookingOverlay for the oldest waiting dish there).

const L = preload("res://scenes/restaurant3d/restaurant_layout_3d.gd")
const CAT_DIALOGUES := [
	preload("res://data/dialogues/cat_first.tres"),
	preload("res://data/dialogues/cat_warm.tres"),
	preload("res://data/dialogues/cat_omen.tres"),
	preload("res://data/dialogues/cat_mark.tres"),
]

var host: Node3D


func _init(owner: Node3D) -> void:
	host = owner


func interact() -> void:
	var at: Vector3 = host.player.position
	if host.planning_panel.visible and at.distance_to(L.BOARD_POSITION) < 2.2:
		host._toggle_planning()
		return
	if host.modal_open():
		return
	if host.cat_node and at.distance_to(host.cat_node.position) < 1.3:
		var dialogue := DialogueLibrary.pick(CAT_DIALOGUES) as Dialogue
		if dialogue:
			host.cat_dialogue.play(dialogue)
		return
	if host.bag.has_goods() and host.bag.near_fridge(at):
		host.bag.store(host.market_stock, host.menu.dishes)
		Sfx.play("bag")
		host._show_note("Cất vô tủ lạnh xong.")
		return
	if at.distance_to(L.COUNTER_POSITION) < 2.1:
		host._open_market()
		return
	if at.distance_to(L.BOARD_POSITION) < 2.2 and not host.shift_running and not host.shift_over:
		host._toggle_planning()
		return
	if not host.shift_running:
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
	if at.distance_to(L.PASS_POSITION) < 1.35:
		host._pickup_ready()
		return
	_cook_here(at)


## At the grill / beer tap: start the oldest waiting dish made there.
func _cook_here(at: Vector3) -> void:
	var at_grill: bool = at.distance_to(L.GRILL_POSITION) < 2.4
	var at_beer: bool = at.distance_to(L.BEER_POSITION) < 1.7
	if not at_grill and not at_beer:
		return
	for i: int in range(host.orders.size()):
		var order: Dictionary = host.orders[i]
		if order.is_empty() or bool(order.get("cooked", false)):
			continue
		var dish: DishData = order["dish"]
		if (at_beer and dish.instant_serve) or (at_grill and not ChefBao.cooks(dish) and not dish.instant_serve):
			host.cooking_table = i
			host.cooking_overlay.start(dish)
			return
	host._show_note("Chưa có món đang chờ tại đây.")


func on_cooking_finished(_dish: DishData, _result: CookingGameBase.Result, multiplier: float) -> void:
	var table: int = host.cooking_table
	host.cooking_table = -1
	if table < 0 or host.orders[table].is_empty():
		return
	host.orders[table]["cooked"] = true
	host.orders[table]["multiplier"] = multiplier
	var visit: Dictionary = host.orders[table].get("visit", {})
	if not visit.is_empty():
		visit["cooked"] = true
	# Rin made it himself, so it goes straight into his hands (cooking needs empty hands).
	if host.carrying_table < 0:
		host.carrying_table = table
		host._show_note("Đem %s tới bàn %d." % [host.orders[table]["dish"].display_name, table + 1])
	else:
		host._show_note("Món bàn %d đã xong!" % (table + 1))
	host._dispatch_ready()


func on_cooking_spilled(dish: DishData) -> void:
	if dish.is_market_dish():
		host.market_stock.spill(dish, 1)
