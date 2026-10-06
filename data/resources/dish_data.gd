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
