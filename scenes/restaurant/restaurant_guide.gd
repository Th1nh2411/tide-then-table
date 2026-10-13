class_name RestaurantGuide
extends Guide
## First-time pointers in the restaurant (see Guide): the LED sign, "Mở
## quán", a plate to pick up, the table to bring it to, the grill, the beer
## tap, the grocery when something runs out, the fridge, a dirty table,
## hiring in the phone, "Sửa quán" and "Ra khơi". Refs are set by the restaurant
## before it enters the tree.

var room: StreetRoom
var rin: RinChef
var customers: CustomerManager
var kitchen: KitchenStation
var stall: MarketStall
var board: MenuBoard
var menu_panel: MenuSetupPanel
var market_panel: MarketPanel
var crew: StaffCrew
var renovation: RenovationMode
var open_button: Button
var renovate_button: Button
var sail_button: Button
## () -> bool: the shop is serving (open or closing with guests inside).
var serving: Callable
var shift_over: Callable


func _ready() -> void:
	blocked = func() -> bool: return kitchen.busy
	super()


func _add_rules() -> void:
	add("menu_board", "Bấm bảng: chọn món", func() -> bool: return board.clickable,
		func() -> Vector2: return _rect_top(room.merged_rect("E").grow_individual(0, 40, 0, 0)),
		func() -> bool: return menu_panel.visible)
	add("open_shop", "Mở quán", _open_shop_active,
		func() -> Vector2: return Guide.control_center(open_button),
		func() -> bool: return serving.call())
	add("pick_plate", "E: cầm món", _pick_plate_active, _pick_plate_target,
		func() -> bool: return rin.carried != null)
	add("serve", "E: mang ra bàn", func() -> bool: return rin.carried != null and _seat_for_carried() >= 0,
		func() -> Vector2: return _rect_top(room.table_rect(maxi(_seat_for_carried(), 0))),
		func() -> bool: return rin.carried == null)
	add("grill", "E: nướng món", _grill_active,
		func() -> Vector2: return _rect_top(room.merged_rect("N")),
		func() -> bool: return kitchen.busy)
	add("pour", "E: rót tháp bia", _pour_active,
		func() -> Vector2: return _cell_top(room.grid.cells_of("U")[0]),
		func() -> bool: return kitchen.busy)
	add("grocery", "E: mua hàng", func() -> bool: return _side_missing() and not market_panel.visible,
		func() -> Vector2: return Guide.screen_of(stall.seller, Vector2(0, -36)),
		func() -> bool: return market_panel.visible)
	add("bulk", "Shift + số: mua sỉ (rẻ hơn)", func() -> bool: return market_panel.visible,
		func() -> Vector2: return market_panel.get_global_rect().position + Vector2(market_panel.size.x - 40, 4))
	add("fridge", "E: cất vào tủ lạnh", func() -> bool: return stall.bag.total() > 0 and not market_panel.visible,
		func() -> Vector2: return _rect_top(room.merged_rect("F")),
		func() -> bool: return stall.bag.total() == 0)
	add("clean", "E: dọn bàn", func() -> bool: return not room.dining.dirty_seats().is_empty(),
		_clean_target,
		func() -> bool: return room.dining.dirty_seats().is_empty())
	add("staff", "J → Nhân viên: thuê người", _staff_active,
		func() -> Vector2: return Guide.screen_of(rin, Vector2(0, -40)),
		func() -> bool: return not crew.roster.hired().is_empty())
	add("renovate", "Nâng cấp quán", func() -> bool: return shift_over.call() and renovate_button.visible,
		func() -> Vector2: return Guide.control_center(renovate_button),
		func() -> bool: return renovation.visible)
	add("sail", "Xong thì ra khơi", _sail_active,
		func() -> Vector2: return Guide.control_center(sail_button))
	add("wave_shop", "C: cả phố chậm lại", func() -> bool: return WaveMark.has_power() and serving.call(),
		wave_badge_target,
		func() -> bool: return WavePower.active)


func _staff_active() -> bool:
	return crew.is_unlocked() and not serving.call() and crew.roster.hired().is_empty() \
		and not crew.roster.candidates().is_empty()


func _open_shop_active() -> bool:
	return menu_panel.visible and open_button.is_visible_in_tree()


func _pick_plate_active() -> bool:
	return serving.call() and rin.carried == null and not customers.shelf.plates.is_empty()


func _pick_plate_target() -> Vector2:
	if customers.shelf.plates.is_empty():
		return Vector2.ZERO
	var slot := maxi(customers.shelf.slots.find(customers.shelf.plates[0]), 0)
	return _cell_top(room.pass_cells()[slot])


func _grill_active() -> bool:
	return serving.call() and not kitchen.busy and kitchen.next_order(false) != null


func _pour_active() -> bool:
	return serving.call() and not kitchen.busy and _beer_in_fridge()


func _clean_target() -> Vector2:
	var dirty := room.dining.dirty_seats()
	return _rect_top(room.table_rect(dirty[0])) if not dirty.is_empty() else Vector2.ZERO


func _sail_active() -> bool:
	return shift_over.call() and sail_button.visible and Guide.is_seen("renovate") and not renovation.visible


func _seat_for_carried() -> int:
	for order in customers.waiting:
		if order.dish == rin.carried.dish and order.visit == rin.carried.visit:
			return order.seat
	return -1


func _beer_in_fridge() -> bool:
	var order := kitchen.next_order(true)
	return order != null and stall.stock.portions(order.dish) > 0


## A table waits for rau / beer and there's none in the fridge or bag.
func _side_missing() -> bool:
	if not serving.call():
		return false
	for order in customers.waiting:
		if order.dish.is_market_dish() and stall.stock.portions(order.dish) == 0 and stall.bag.count(order.dish) == 0:
			return true
	return false


func _rect_top(rect: Rect2) -> Vector2:
	return Guide.screen_of_rect(room, rect)


func _cell_top(cell: Vector2i) -> Vector2:
	return _rect_top(room.grid.cell_rect(cell))
