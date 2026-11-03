class_name RestaurantHud3D
extends CanvasLayer
## 3D restaurant HUD, horror build: no numbers (no clock, day, tallies, stars
## or Đóng sớm button; the shift closes by itself, T still closes early).
## Only the order slips on a ticket rail (OrderTicket3D) stay: they tell Rin
## which table wants what. Shown while the shift runs.

## Kept for the setup's connection; nothing on screen emits it any more.
signal close_requested

## Ticket rail across the top left.
const RAIL := Rect2(8, 4, 290, 56)

var room: Node3D
## The rail holding the order slips (kept under its old name).
var ticket_row: TicketRail3D


func setup(room_node: Node3D, _theme: Theme = null, _style: StyleBoxFlat = null) -> void:
	room = room_node
	ticket_row = TicketRail3D.new()
	ticket_row.position = RAIL.position
	ticket_row.size = RAIL.size
	add_child(ticket_row)


func _process(_delta: float) -> void:
	if room == null:
		return
	var running: bool = room.shift_running
	visible = running
	if not visible:
		return
	var orders: Array[Dictionary] = room.orders
	ticket_row.refresh(orders)
