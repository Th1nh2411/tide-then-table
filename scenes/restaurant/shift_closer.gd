class_name ShiftCloser
extends Node
## The shift's books and its closing (restaurant_scene owns the flow): counts
## money, guests served / lost and market spending while serving, then
## `close()` clears the kitchen, stores leftovers, sends back unserved
## regulars' fish, pays the staff, rates the day, saves the day record and
## returns the summary text (ShiftReport).

signal message_requested(text: String, seconds: float)

var customers: CustomerManager
var stall: MarketStall
var market_panel: MarketPanel
var crew: StaffCrew
var chef: ChefBao
var rin: RinChef
var fish_catalog: FishCatalog
## Price multiplier from today's menu variety (set when the shop opens).
var variety_multiplier: float = 1.0

var earned: int = 0
var market_spent: int = 0
var served: int = 0
var left_angry: int = 0


func _ready() -> void:
	customers.customer_served.connect(_on_customer_served)
	customers.customer_left_angry.connect(_on_customer_left_angry)
	stall.bought.connect(func(_dish: DishData, cost: int) -> void: market_spent += cost)


## Everything after the last guest left; returns the summary text.
func close(reason: String, plan: MenuPlan) -> String:
	rin.carried = null
	customers.shelf.clear()  # plates left on the table are wasted
	chef.clear()
	var leftover := plan.total_portions()
	plan.clear(GameState.storage)
	stall.open = false
	stall.store_all()  # whatever is still in Rin's bag
	market_panel.close_panel()
	# Uncooked regular orders go back to storage.
	for visit in customers.uncooked_regular_visits():
		FishOrders.release(visit)
	var order_lines := FishOrders.expire_after_shift(fish_catalog)
	var wages := crew.pay_wages()
	for person in crew.roster.hired():
		GameState.set_flag("worked_" + person.id)  # story scenes after their first shift
	var stars := DayRating.stars(served, left_angry, variety_multiplier < 1.0)
	GameState.last_rating = stars
	GameState.add_day_record({"day": GameState.day, "earned": earned, "market": market_spent,
		"rating": stars, "served": served, "left": left_angry, "wages": wages})
	return ShiftReport.text({"reason": reason, "stars": stars, "earned": earned,
		"market": market_spent, "wages": wages, "served": served, "left": left_angry,
		"variety": variety_multiplier, "leftover": leftover}, order_lines)


func _on_customer_left_angry() -> void:
	left_angry += 1
	Sfx.play("grumble")
	if left_angry == 1:
		message_requested.emit("Khách bỏ về rồi... phải nhanh tay hơn.", 2.5)


func _on_customer_served(price: int, tip: int) -> void:
	Sfx.play("coins")
	earned += price + tip
	served += 1
