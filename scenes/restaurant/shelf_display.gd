class_name ShelfDisplay
extends Control
## Draws the kitchen side of the dining room: the shelf with the plates
## waiting on it (from CustomerManager.shelf), the trash bin and the kitchen
## door sign, so the player can see what is ready without opening the kitchen.

@export var customers: CustomerManager
@export var shelf_origin: Vector2 = Vector2(96, 186)
@export var slot_width: float = 16.0
@export var door_x: float = 150.0
@export var bin_position: Vector2 = Vector2(20, 246)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var shelf := customers.shelf
	# Shelf board above the counter.
	draw_rect(Rect2(shelf_origin + Vector2(-4, 8), Vector2(slot_width * shelf.capacity + 4, 3)), Color(0.45, 0.3, 0.2))
	for i in shelf.plates.size():
		var at := shelf_origin + Vector2(i * slot_width, 0)
		draw_rect(Rect2(at + Vector2(0, 5), Vector2(12, 3)), Color.WHITE)
		draw_rect(Rect2(at + Vector2(2, 1), Vector2(8, 4)), shelf.plates[i].dish.color)
	# Trash bin.
	draw_rect(Rect2(bin_position, Vector2(12, 14)), Color(0.35, 0.4, 0.35))
	draw_rect(Rect2(bin_position + Vector2(-1, -2), Vector2(14, 3)), Color(0.25, 0.3, 0.25))
	# Kitchen door marker.
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2(door_x - 2, 200), Vector2(4, 62)), Color(0.3, 0.2, 0.12))
	draw_string(font, Vector2(door_x - 14, 196), "BẾP", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 0.9, 0.6))
