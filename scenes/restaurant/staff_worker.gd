class_name StaffWorker
extends StreetPerson
## A hired helper on the street restaurant (StaffData: name, colour, speed).
## StaffCrew gives the tasks (carry a plate out, clean a table); `working`
## while doing one.

var data: StaffData
var working: bool = false


func _ready() -> void:
	body_color = data.body_color
	speed = data.walk_speed
	apron = true
	label = data.display_name


## Walks the grid path to `target` (await it).
func go(room: StreetRoom, target: Vector2i) -> void:
	await walk_and_wait(room.grid.path(room.grid.to_cell(position), target))
