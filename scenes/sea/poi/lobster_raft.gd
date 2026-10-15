class_name LobsterRaft
extends PointOfInterest
## Anh Út's lobster raft on the reef: buys fish from the hold right now at
## a low "night market" price, to make room without going back to dock —
## the whole hold at once, or picked one by one in the hold window (sell mode:
## drag onto "Bán" / right-click).

@export var hold_manager: HoldManager
## Fraction of base price × size × quality paid per fish.
@export var sell_ratio: float = 0.5


func _interact() -> void:
	var items := hold_manager.hold.items.duplicate()
	if items.is_empty():
		await dialog.ask(title, "Anh Út: \"Khoang trống trơn mà ghé chi? Đi câu đi em.\"",
			PackedStringArray(["Đi tiếp"]))
		return
	var value := sale_value(items, sell_ratio)
	var choice := await dialog.ask(title,
		"Anh Út: \"Khoang đầy hả? Để anh mua đỡ, giá chợ đêm thôi nghen.\"\n(%d con trong khoang)" % items.size(),
		PackedStringArray(["Chọn con để bán", "Bán hết khoang: %dk" % value, "Thôi, để đem về quán"]))
	if choice == 0:
		_sell_some()
		return
	if choice != 1:
		return
	for item: InventoryItem in items:
		hold_manager.hold.remove(item)
	GameState.add_money(value)
	hud.flash_message("Bán cho anh Út %d con, được %dk." % [items.size(), value], 2.0)


## Opens the hold in sell mode; tells how much it came to when closed.
func _sell_some() -> void:
	var ui := hold_manager.hold_ui
	var total: Array[int] = [0, 0]  # fish, money
	var on_sold := func(_item: InventoryItem, price: int) -> void:
		total[0] += 1
		total[1] += price
	ui.sold.connect(on_sold)
	ui.open_sell("bè tôm hùm anh Út (giá chợ đêm)", func(item: InventoryItem) -> int:
		return sale_value([item], sell_ratio))
	await ui.closed
	ui.sold.disconnect(on_sold)
	if total[0] > 0:
		hud.flash_message("Bán cho anh Út %d con, được %dk." % total, 2.0)


## What the raft pays for these items.
static func sale_value(items: Array, ratio: float) -> int:
	var total := 0.0
	for item: InventoryItem in items:
		total += item.fish.base_price * item.size * item.quality * ratio
	return roundi(total)


func _draw() -> void:
	# Floating frame of bamboo with net cages and a lantern pole.
	draw_rect(Rect2(-18, -12, 36, 24), Color(0.5, 0.38, 0.22))
	for x in [-12, 0, 12]:
		draw_rect(Rect2(x - 5, -8, 10, 16), Color(0.15, 0.3, 0.4))
	draw_line(Vector2(16, -12), Vector2(16, -24), Color(0.4, 0.3, 0.2), 2.0)
	draw_circle(Vector2(16, -25), 2.5, lamp_color)
	super()
