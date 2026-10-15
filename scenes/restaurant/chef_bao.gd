class_name ChefBao
extends StreetPerson
## Bảo, the chef, behind the food cart's stove (from day 1). While the shop
## serves he cooks by himself, oldest ticket first, every dish that isn't
## Rin's (`cooks()`: steamed / stir-fried, rau muống; Rin grills and pours
## the beer): takes the portion (menu, the grocery stock, or a regular's
## reserved fish), cooks for a while (faster and better with the kitchen
## upgrade) and puts the plate on the plate table, waiting if it's full.
## Out of rau: he shouts for Rin to go to the grocery. Rin can talk to him
## (child Talker; "!" when there's news). Rau from older batches sells for
## less (KitchenLogic.freshness_multiplier on its freshness).

signal message_requested(text: String)

@export var display_name: String = "Bảo"
@export var customers: CustomerManager
@export var stall: MarketStall
@export var rin: StreetPerson
@export var kitchen_upgrade: UpgradeData
## Seconds per dish and price multiplier, by kitchen upgrade level.
@export var cook_seconds_by_level: Array[float] = [7.0, 5.5, 4.0]
@export var quality_by_level: Array[float] = [1.0, 1.05, 1.15]

## The shop is serving (set by the restaurant every frame).
var serving: bool = false
var cooking_dish: DishData

var _plan: MenuPlan
var _left: float = 0.0
var _total: float = 1.0
var _items: Array[InventoryItem] = []
var _visit: Dictionary = {}
var _freshness_scale: float = 1.0  # grocery goods: older rau sells for less
var _done: DishShelf.Plate  # cooked, waiting for room on the plate table
var _shouted: Dictionary = {}  # dish -> true: already asked Rin to buy it


func _ready() -> void:
	body_color = Color(0.85, 0.5, 0.2)
	apron = true
	hat = false
	label = display_name
	facing = Vector2i.DOWN


func setup(plan: MenuPlan) -> void:
	_plan = plan


## Bảo's dishes: everything but grilled ones and drinks (Rin's).
static func cooks(dish: DishData) -> bool:
	return dish.cook_type != DishData.CookType.GRILL and not dish.instant_serve


func is_busy() -> bool:
	return cooking_dish != null or _done != null


func can_talk() -> bool:
	return true


## Closing: drop whatever is on the stove.
func clear() -> void:
	cooking_dish = null
	_done = null
	_shouted.clear()


func _process(delta: float) -> void:
	super(delta)
	if not serving or _plan == null:
		return
	if _done:
		if customers.shelf.add(_done):
			_done = null
		return
	if cooking_dish:
		_left -= delta
		if _left <= 0.0:
			_done = DishShelf.Plate.new(cooking_dish, _items, _by_level(quality_by_level) * _freshness_scale, _visit)
			cooking_dish = null
		return
	_start_next()


func _start_next() -> void:
	for order in customers.waiting:
		var dish := order.dish
		if not cooks(dish):
			continue
		var items: Array[InventoryItem] = []
		_freshness_scale = 1.0
		if not order.visit.is_empty():
			if order.visit.get("cooked", false):
				continue
			order.visit["cooked"] = true
			items.append(order.visit["item"])
		elif not _needs_more(dish):
			continue
		elif dish.always_available:
			if not stall.stock.take(dish):
				_shout(dish)
				continue
			_shouted.erase(dish)
			_freshness_scale = KitchenLogic.freshness_multiplier(stall.stock.last_freshness)
		elif _plan.get_portion_count(dish) > 0:
			items = _plan.take_portion(dish)
		else:
			continue
		_start(dish, items, order.visit)
		return


## More lines wait for `dish` than plates exist (plate table, staff and Rin's hands).
func _needs_more(dish: DishData) -> bool:
	var waiting := customers.waiting.filter(func(o: TableOrder) -> bool: return o.dish == dish and o.visit.is_empty()).size()
	var plates := customers.plates_ready(dish)
	if rin.carried and rin.carried.dish == dish and rin.carried.visit.is_empty():
		plates += 1
	return waiting > plates


func _start(dish: DishData, items: Array[InventoryItem], visit: Dictionary) -> void:
	cooking_dish = dish
	_items = items
	_visit = visit
	_total = _by_level(cook_seconds_by_level)
	_left = _total


func _shout(dish: DishData) -> void:
	if not _shouted.has(dish):
		_shouted[dish] = true
		if stall.bag.count(dish) > 0:
			message_requested.emit("Bảo: Rau còn trong túi kìa Rin, cất vô tủ lạnh đi!")
		else:
			message_requested.emit("Bảo: Hết %s rồi Rin ơi! Chạy qua tạp hoá %s mua đi!" % [dish.display_name, stall.seller_name])


func _by_level(table: Array[float]) -> float:
	var level := GameState.get_upgrade_level(kitchen_upgrade.id) if kitchen_upgrade else 0
	return table[clampi(level, 0, table.size() - 1)]


func is_busy_pose() -> bool:
	return cooking_dish != null


func _draw() -> void:
	super()
	if cooking_dish:  # tossing the wok, steam, progress bar
		var toss := sin(Time.get_ticks_msec() * 0.02) * 2.0
		draw_circle(Vector2(6, -10 + toss), 4.0, Color(0.15, 0.15, 0.17))
		draw_circle(Vector2(6, -11 + toss), 2.2, cooking_dish.color)
		for k in 2:
			var t := fmod(Time.get_ticks_msec() * 0.001 + k * 0.5, 1.0)
			draw_circle(Vector2(6 + k * 3, -16 - t * 10.0), 2.0 + t * 2.0, Color(1, 1, 1, 0.5 * (1.0 - t)))
		draw_rect(Rect2(-10, -44, 20, 3), Color(0, 0, 0, 0.5))
		draw_rect(Rect2(-10, -44, 20.0 * (1.0 - _left / _total), 3), Color(1.0, 0.8, 0.3))
	elif _done:  # plate ready, the plate table is full
		StreetProps.draw_plate(self, _done, Vector2(0, -44))
	var talker := get_node_or_null("Talker") as Talker
	if talker and not is_busy() and talker.has_news():
		draw_string(ThemeDB.fallback_font, Vector2(-3, -44), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
			Color(1, 0.85, 0.3))
