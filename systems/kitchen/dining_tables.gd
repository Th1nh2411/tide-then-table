class_name DiningTables
extends RefCounted
## Table states (one seat per table): FREE -> TAKEN (a customer sits) ->
## DIRTY (they ate and left) -> FREE once cleaned (by Bảo or Rin). A customer
## who leaves without eating leaves the table FREE. Also the plate being
## eaten from at each table. Pure logic; StreetRoom draws the tables.

enum State { FREE, TAKEN, DIRTY }

var states: Array[State] = []
## A plate being eaten from, per table (null if none).
var plates: Array[DishShelf.Plate] = []


func setup(count: int) -> void:
	states.resize(count)
	states.fill(State.FREE)
	plates.resize(count)
	plates.fill(null)


func count() -> int:
	return states.size()


## First free table, or -1.
func free_seat() -> int:
	return states.find(State.FREE)


## All free tables.
func free_seats() -> Array[int]:
	var result: Array[int] = []
	for i in states.size():
		if states[i] == State.FREE:
			result.append(i)
	return result


func take(seat: int) -> void:
	states[seat] = State.TAKEN


## The customer left without eating.
func release(seat: int) -> void:
	states[seat] = State.FREE
	plates[seat] = null


## Food arrived at this table.
func put_plate(seat: int, plate: DishShelf.Plate) -> void:
	plates[seat] = plate


## The customer ate and left: dirty until cleaned.
func make_dirty(seat: int) -> void:
	states[seat] = State.DIRTY


func clean(seat: int) -> void:
	if states[seat] == State.DIRTY:
		states[seat] = State.FREE
		plates[seat] = null


func dirty_seats() -> Array[int]:
	var result: Array[int] = []
	for i in states.size():
		if states[i] == State.DIRTY:
			result.append(i)
	return result
