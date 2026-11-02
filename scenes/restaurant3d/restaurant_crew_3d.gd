class_name RestaurantCrew3D
extends RefCounted
## Bảo cooks every dish except beer, oldest table first, and puts it on the
## plate bench. Reads and writes the host's `orders`.

## Seconds Bảo takes per dish.
const COOK_SECONDS := 5.0

var host: Node3D
var bao_table: int = -1
var bao_seconds: float = 0.0

func _init(owner: Node3D) -> void:
	host = owner

## True for the dishes Bảo makes (everything but drinks).
static func cooks(dish: DishData) -> bool:
	return not dish.instant_serve

func tick_bao(delta: float) -> void:
	var orders: Array[Dictionary] = host.orders
	if bao_table >= 0:
		if orders[bao_table].is_empty():
			bao_table = -1
		else:
			bao_seconds -= delta
			host.bao_model.rotation.y = sin(host.step_clock * 7.0) * 0.08
			if bao_seconds <= 0.0:
				var table: int = bao_table
				bao_table = -1
				orders[table]["cooked"] = true
				host._show_note("Bảo: Món bàn %d xong rồi Rin!" % (table + 1))
	if bao_table < 0:
		host.bao_label.text = "Bảo • bếp"
		for i: int in range(orders.size()):
			if orders[i].is_empty() or bool(orders[i].get("cooked", false)):
				continue
			var dish: DishData = orders[i]["dish"]
			if cooks(dish):
				bao_table = i
				bao_seconds = COOK_SECONDS
				host.bao_label.text = "Bảo: " + dish.display_name
				break
