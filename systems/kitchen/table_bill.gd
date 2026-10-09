class_name TableBill
extends RefCounted
## What a table pays for the plates it ate: menu dishes by
## KitchenLogic.calc_price × menu variety × the well-off bonus; a regular's
## plate by their order's reward × the cooking result. Tip on top only if
## the party kept enough patience (never for regulars). Pure logic, no nodes.


static func plate_price(plate: DishShelf.Plate, variety: float, rich_scale: float) -> int:
	if not plate.visit.is_empty():
		return roundi(int(plate.visit["order"]["reward"]) * plate.cook_multiplier)
	return roundi(KitchenLogic.calc_price(plate.dish, plate.cook_multiplier, plate.ingredients) * variety * rich_scale)


static func total(plates: Array[DishShelf.Plate], variety: float, rich_scale: float) -> int:
	var sum := 0
	for plate in plates:
		sum += plate_price(plate, variety, rich_scale)
	return sum


static func tip(price: int, patience: float, threshold: float, ratio: float) -> int:
	return roundi(price * ratio) if patience > threshold else 0
