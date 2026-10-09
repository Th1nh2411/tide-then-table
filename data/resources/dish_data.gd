class_name DishData
extends Resource
## One dish on the menu. One .tres per dish lives in res://data/dishes/.

enum CookType { GRILL, STEAM, STIR }

@export var id: String = ""
@export var display_name: String = ""
## fish_id -> how many of that fish the dish needs.
@export var ingredients: Dictionary[String, int] = {}
@export var cook_type: CookType = CookType.GRILL
@export var base_price: int = 50
## Placeholder color for the order bubble.
@export var color: Color = Color.WHITE
## Market dishes (no `ingredients`): price of one buy at Cô Năm's grocery
## next door (MarketStall), which gives `market_pack` units (a bunch of rau =
## 1 portion; a keg of draft beer = 20 litres).
@export var market_cost: int = 0
@export var market_pack: int = 1
## Units one serving uses (a beer tower = 3 litres).
@export var portion_units: int = 1
## Unit word for stock lines ("phần", "lít") and the name of one buy
## ("bình 20 lít"; empty = sold per portion).
@export var unit_name: String = "phần"
@export var pack_label: String = ""
## Bought goods that keep between days (beer); others are wasted at closing.
@export var keeps_overnight: bool = false


## Always on the menu, never planned (no menu slot); customers sometimes pick
## it, and order only it once the seafood is sold out. Cooking it still needs
## its goods (market dishes) — Rin has to run and buy more.
@export var always_available: bool = false
## A drink: no cooking, Rin pours it at the tap (BeerPourGame).
@export var instant_serve: bool = false


## Made from goods bought at the grocery rather than the player's catch.
func is_market_dish() -> bool:
	return ingredients.is_empty() and market_cost > 0


## Grocery price text: "10k/phần" or "bình 20 lít: 150k".
func market_text() -> String:
	if pack_label:
		return "%s: %dk" % [pack_label, market_cost]
	return "%dk/%s" % [market_cost, unit_name]
