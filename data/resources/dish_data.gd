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
## Market dishes (no `ingredients`): Rin buys one portion of produce at the
## stall next door for this price (MarketStall); unused produce is thrown
## away at closing.
@export var market_cost: int = 0


## Always on the menu, never planned (no menu slot); customers sometimes pick
## it, and order only it once the seafood is sold out. Cooking it still needs
## its produce (market dishes) — Rin has to run and buy more.
@export var always_available: bool = false


## Cooked from produce bought at the stall rather than the player's catch.
func is_market_dish() -> bool:
	return ingredients.is_empty() and market_cost > 0
