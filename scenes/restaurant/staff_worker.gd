class_name StaffWorker
extends StreetPerson
## A hired helper on the street restaurant (StaffData: name, colour, speed).
## StaffCrew gives the tasks (carry a plate out, clean a table); `working`
## while doing one. Rin can talk to them between tasks (Talker child added by
## StaffCrew when they have lines; "!" when there's something new).

var data: StaffData
var working: bool = false


func _ready() -> void:
	body_color = data.body_color
	speed = data.walk_speed
	apron = true
	label = data.display_name


## Their own sheet ("characters/vy") if drawn, else the shared helper look.
func sprite_name() -> String:
	var own := "characters/" + data.id
	return own if Art.has(own) else "characters/staff"


func can_talk() -> bool:
	return not working and carried == null


func _draw() -> void:
	super()
	var talker := get_node_or_null("Talker") as Talker
	if talker and not working and talker.has_news():
		draw_string(ThemeDB.fallback_font, Vector2(-3, -44), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
			Color(1, 0.85, 0.3))


## Walks the grid path to `target` (await it).
func go(room: StreetRoom, target: Vector2i) -> void:
	await walk_and_wait(room.grid.path(room.grid.to_cell(position), target))
