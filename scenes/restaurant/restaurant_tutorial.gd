class_name RestaurantTutorial
extends Node
## Day-1 tips in the restaurant, advancing with what the player does:
## shop open -> walked to the food cart -> first dish cooked -> first dirty
## table -> evening after closing. Does nothing on later days (the
## full controls live in the Hướng dẫn screen).

signal tip_requested(text: String)

@export var customers: CustomerManager
@export var kitchen: KitchenStation
@export var tip_seconds: float = 7.0

enum Step { WAIT_OPEN, GO_KITCHEN, COOK, SERVE, CLEAN, DONE }

var _step: Step = Step.DONE


func _ready() -> void:
	if GameState.is_first_day():
		_step = Step.WAIT_OPEN


## Arrived at the restaurant (menu not prepared yet).
func on_restaurant_ready() -> void:
	if _step == Step.WAIT_OPEN:
		tip_requested.emit("Bấm \"Chuẩn bị menu\" để chọn món bán hôm nay, xong bấm \"Mở quán\".")


## The shop just opened.
func on_shop_opened() -> void:
	if _step == Step.WAIT_OPEN:
		_step = Step.GO_KITCHEN
		tip_requested.emit("Khách sẽ gọi món (phiếu hiện trên cùng). WASD đi tới xe đẩy bên trái để nấu.")


## The summary was closed: the evening is free.
func on_evening() -> void:
	if GameState.is_first_day():
		_step = Step.DONE
		tip_requested.emit("Bấm \"Sửa quán\" để nâng cấp quán, J -> Nâng cấp để mua đồ nghề. Xong thì bấm \"Ra khơi\".")


func _process(_delta: float) -> void:
	match _step:
		Step.GO_KITCHEN:
			if kitchen.is_rin_near():
				_step = Step.COOK
				tip_requested.emit("Ở gần xe đẩy, bấm số (hoặc click) món trên hàng món trên cùng để nấu.")
		Step.COOK:
			if kitchen.rin.carried or not customers.shelf.plates.is_empty():
				_step = Step.SERVE
				tip_requested.emit("Món xong! Mang tới bàn đang nhấp nháy xanh, quay mặt vào bàn bấm E để đặt.")
		Step.SERVE:
			if not customers.tables.dirty_seats().is_empty():
				_step = Step.CLEAN
				tip_requested.emit("Khách ăn xong để lại bàn bẩn: quay mặt vào bàn bấm E để dọn, dọn rồi mới có khách mới ngồi.")
