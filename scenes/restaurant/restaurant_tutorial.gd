class_name RestaurantTutorial
extends Node
## Day-1 tips in the restaurant, advancing with what the player does:
## shop open -> entered the kitchen -> first plate on the shelf -> first
## dirty table -> evening after closing. Does nothing on later days (the
## full controls live in the Hướng dẫn screen).

signal tip_requested(text: String)

@export var customers: CustomerManager
@export var kitchen_view: KitchenView
@export var tip_seconds: float = 7.0

enum Step { WAIT_OPEN, GO_KITCHEN, COOK, SERVE, CLEAN, DONE }

var _step: Step = Step.DONE


func _ready() -> void:
	if GameState.is_first_day():
		_step = Step.WAIT_OPEN


## The shop just opened.
func on_shop_opened() -> void:
	if _step == Step.WAIT_OPEN:
		_step = Step.GO_KITCHEN
		tip_requested.emit("Khách sẽ gọi món. A/D đi tới cửa BẾP bên trái, bấm E để vào nấu.")


## The summary was closed: the evening is free.
func on_evening() -> void:
	if GameState.is_first_day():
		_step = Step.DONE
		tip_requested.emit("Bấm \"Nâng cấp\" để mua đồ (hoặc J -> tab Nâng cấp). Xong thì bấm \"Ra khơi\".")


func _process(_delta: float) -> void:
	match _step:
		Step.GO_KITCHEN:
			if kitchen_view.visible:
				_step = Step.COOK
				tip_requested.emit("Bấm khay (hoặc phím số) để nấu món khách gọi. Món xong sẽ nằm trên kệ.")
		Step.COOK:
			if not customers.shelf.plates.is_empty():
				_step = Step.SERVE
				tip_requested.emit("Món lên kệ rồi! Bấm E để ra khỏi bếp. Bảo sẽ tự bưng cho khách vào trước.")
		Step.SERVE:
			if not customers.tables.dirty_seats().is_empty():
				_step = Step.CLEAN
				tip_requested.emit("Khách ăn xong để lại bàn bẩn. Bảo sẽ dọn, hoặc đứng cạnh bàn bấm E để Rin dọn.")
