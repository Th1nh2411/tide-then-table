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
## 1 portion; a tower's worth of draft beer = 3 litres).
@export var market_cost: int = 0
@export var market_pack: int = 1
## Units one serving uses (a beer tower = 3 litres).
@export var portion_units: int = 1
## Unit word for stock lines ("phần", "lít") and the name of one buy
## ("1 tháp"; empty = "1 <unit_name>").
@export var unit_name: String = "phần"
@export var pack_label: String = ""
## Bulk buy, cheaper: `bulk_packs` packs at once for `bulk_cost` (0 = none),
## named `bulk_label` ("10 tháp"; empty = "<n> <unit_name>").
@export var bulk_packs: int = 0
@export var bulk_cost: int = 0
@export var bulk_label: String = ""
## Bought goods that keep between days (beer); others are wasted at closing.
@export var keeps_overnight: bool = false


## Always on the menu, never planned (no menu slot); customers sometimes pick
## it, and order only it once the seafood is sold out. Cooking it still needs
## its goods (market dishes) — Rin has to run and buy more.
@export var always_available: bool = false
## First day it's sold (beer comes on day 2, so day 1 stays simple).
@export var unlock_day: int = 1
## A drink: no cooking, Rin pours it at the tap (BeerPourGame).
@export var instant_serve: bool = false


## Always on today's menu (always available and already unlocked).
func on_menu_today() -> bool:
	return always_available and GameState.day >= unlock_day


## Made from goods bought at the grocery rather than the player's catch.
func is_market_dish() -> bool:
	return ingredients.is_empty() and market_cost > 0


func has_bulk() -> bool:
	return bulk_packs > 1 and bulk_cost > 0


func buy_cost(bulk: bool) -> int:
	return bulk_cost if bulk else market_cost


## Units one buy gives.
func buy_units(bulk: bool) -> int:
	return market_pack * (bulk_packs if bulk else 1)


## One buy with its price: "1 phần 10k", "10 tháp 200k".
func buy_text(bulk: bool) -> String:
	var label := pack_label if pack_label else "1 %s" % unit_name
	if bulk:
		label = bulk_label if bulk_label else "%d %s" % [buy_units(true), unit_name]
	return "%s %dk" % [label, buy_cost(bulk)]


## Grocery price text: "1 phần 10k · 10 phần 80k".
func market_text() -> String:
	return buy_text(false) + ((" · " + buy_text(true)) if has_bulk() else "")
