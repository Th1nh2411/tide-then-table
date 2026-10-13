class_name MarketStall
extends Node
## Cô Năm's grocery next door (the "V" counter of the StreetRoom map): E in
## front of the counter (`reach`) opens the list of what she sells
## (MarketPanel); each buy is `market_pack` units of a market dish's goods (a
## bunch of rau, a tower's 3 L of beer) for its `market_cost`, or the
## cheaper bulk buy (`bulk_packs` at once for `bulk_cost`), before opening or during
## the shift (not after closing). Bought goods go into Rin's shopping `bag`;
## he has to carry them home and E on the fridge ("F") to put them in
## `stock` (MarketStock on GameState.pantry, so beer keeps between days) —
## only then can Bảo cook the rau and Rin pour the beer.

signal browse_requested
signal bought(dish: DishData, cost: int)
signal message_requested(text: String)

@export var room: StreetRoom
## What the grocery sells: market dishes (their goods, one portion per buy).
@export var products: Array[DishData] = []
@export var seller_name: String = "Cô Năm"
@export var seller: Node2D
## Where Rin can buy from, relative to Cô Năm: anywhere along the counter
## (x: ± px) and up to this far below her (y px), facing any way.
@export var reach: Vector2 = Vector2(56, 50)

## The fridge (what the kitchen uses).
var stock := MarketStock.new(GameState.pantry)
## Bought, still in Rin's hands.
var bag := MarketStock.new({})
## Set by the restaurant: false once the day's shift is over.
var open: bool = true


## Rin stands in front of the counter.
func can_reach(rin: StreetPerson) -> bool:
	var d := rin.position - seller.position
	return absf(d.x) <= reach.x and d.y > 0.0 and d.y <= reach.y


## E by Rin; false = he isn't at the stall.
func interact(rin: StreetPerson) -> bool:
	if not can_reach(rin):
		return false
	if open:
		browse_requested.emit()
	else:
		message_requested.emit("%s: Dọn hàng rồi con ơi, mai ghé nha." % seller_name)
	return true


## One buy of `dish`'s goods into the bag; false if the money isn't enough.
## `bulk`: the cheaper bulk buy (DishData.bulk_packs packs at once).
func buy(dish: DishData, bulk: bool = false) -> bool:
	bulk = bulk and dish.has_bulk()
	var cost := dish.buy_cost(bulk)
	if not open or not GameState.spend_money(cost):
		message_requested.emit("Không đủ tiền... cần %dk." % cost)
		return false
	bag.add(dish, dish.buy_units(bulk))
	Sfx.play("bag")
	bought.emit(dish, cost)
	return true


## E on the fridge with a full bag would put it away.
func can_store_at(cell: Vector2i) -> bool:
	return bag.total() > 0 and room.grid.kind(cell) == "F"


## E on `cell`: the fridge with a full bag -> put the goods away.
func store_at(cell: Vector2i) -> bool:
	if not can_store_at(cell):
		return false
	store_all()
	Sfx.play("bag")
	message_requested.emit("Cất vô tủ lạnh xong.")
	return true


## Bag -> fridge (also at closing, so nothing is lost in Rin's hands).
func store_all() -> void:
	bag.move_into(stock, products)
