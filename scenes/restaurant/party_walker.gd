class_name PartyWalker
extends RefCounted
## Moves a party on the street restaurant: from the parked bike (or a
## pavement edge "D") to the table — leader on the stool, second guest on the
## spare one — and back out; the bike rides off once both are back.

var room: StreetRoom
var bikes: CustomerBikes
var layer: Node2D
var rng := RandomNumberGenerator.new()


func _init(p_room: StreetRoom, p_bikes: CustomerBikes, p_layer: Node2D) -> void:
	room = p_room
	bikes = p_bikes
	layer = p_layer
	rng.randomize()


## Adds the party at `from` and walks them to their table.
func walk_in(customer: Customer, from: Vector2i) -> void:
	var table: Dictionary = room.tables[customer.seat]
	customer.position = room.grid.to_world(from)
	layer.add_child(customer)
	customer.go_to_seat(room.grid.path(from, table["chair"]))
	if customer.companion:
		var guest := customer.companion
		guest.position = customer.position + Vector2(-6, 2)
		layer.add_child(guest)
		guest.go_to_seat(room.grid.path(from, table["spare"]))


## Walks the party back to the bike (which rides off) or off the pavement,
## then frees them (await it).
func walk_out(customer: Customer) -> void:
	var exit := customer.bike.parking if customer.bike else entrance()
	var guest := customer.companion
	if guest:
		guest.leave(room.grid.path(room.grid.to_cell(guest.position), exit))
	await customer.leave(room.grid.path(room.grid.to_cell(customer.position), exit))
	while guest and guest.is_walking():
		await customer.get_tree().process_frame
	if customer.bike:
		bikes.depart(customer.bike)
	if guest:
		guest.queue_free()
	customer.queue_free()


## A random pavement edge cell for people on foot.
func entrance() -> Vector2i:
	var doors := room.grid.cells_of("D")
	return doors[rng.randi() % doors.size()]
