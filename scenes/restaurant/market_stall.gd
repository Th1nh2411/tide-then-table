class_name MarketStall
extends Node
## Cô Năm's vegetable & meat stall next door (the "V" counter cells of the
## StreetRoom map): E on the counter buys one portion of `product`'s produce
## for its `market_cost`, before opening or during the shift (not after
## closing). The produce goes into `stock` (MarketStock) for the kitchen.

signal bought(dish: DishData, cost: int)
signal message_requested(text: String)

@export var room: StreetRoom
## What the stall sells (a market dish: its produce, one portion per buy).
@export var product: DishData
@export var seller_name: String = "Cô Năm"

var stock := MarketStock.new()
## Set by the restaurant: false once the day's shift is over.
var open: bool = true


func is_stall(cell: Vector2i) -> bool:
	return room.grid.kind(cell) == "V"


## E on `cell`; false = not the stall.
func interact(cell: Vector2i) -> bool:
	if not is_stall(cell):
		return false
	if not open:
		message_requested.emit("%s: Dọn hàng rồi con ơi, mai ghé nha." % seller_name)
	elif not GameState.spend_money(product.market_cost):
		message_requested.emit("Không đủ tiền mua %s (%dk)" % [product.display_name, product.market_cost])
	else:
		stock.add(product)
		bought.emit(product, product.market_cost)
		message_requested.emit("%s: Của con nè! -%dk · đủ nấu %d phần %s" % [seller_name, product.market_cost,
			stock.count(product), product.display_name])
	return true
