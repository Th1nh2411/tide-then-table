class_name OffscreenMarkers
extends Control
## Arrows on the screen edge pointing at important things that are off
## camera: the dock, the player's nets (group "net_buoys") and, once the fog
## is open, the whirlpool. Shows the distance in "m" (10 px = 1 m).

@export var dock: Node2D
@export var fog_area: FogArea
@export var boat: Boat
## Distance from the screen edge.
@export var margin: float = 16.0
@export var dock_color: Color = Color(1.0, 0.9, 0.4)
@export var net_color: Color = Color(1.0, 0.55, 0.2)
@export var fog_color: Color = Color(0.4, 1.0, 0.9)
@export var pixels_per_meter: float = 10.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	_draw_marker(dock.global_position, "Bến", dock_color)
	for buoy: Node2D in get_tree().get_nodes_in_group("net_buoys"):
		_draw_marker(buoy.global_position, "Lưới", net_color)
	if fog_area.visible:
		_draw_marker(fog_area.get_whirlpool_position(), "???", fog_color)


func _draw_marker(world_pos: Vector2, label: String, color: Color) -> void:
	# World -> screen through the camera's canvas transform.
	var screen := get_viewport().get_canvas_transform() * world_pos
	var area := get_viewport_rect().grow(-margin)
	if area.has_point(screen):
		return
	var center := area.get_center()
	var direction := (screen - center).normalized()
	# Push from the center along `direction` until we hit the inner rect edge.
	var reach := INF
	if direction.x != 0.0:
		reach = minf(reach, area.size.x * 0.5 / absf(direction.x))
	if direction.y != 0.0:
		reach = minf(reach, area.size.y * 0.5 / absf(direction.y))
	var tip := center + direction * reach

	var side := direction.orthogonal() * 6.0
	draw_colored_polygon(PackedVector2Array([tip, tip - direction * 12.0 + side, tip - direction * 12.0 - side]), color)
	var meters := roundi(boat.global_position.distance_to(world_pos) / pixels_per_meter)
	var text := "%s %dm" % [label, meters]
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9)
	# Keep the label inside the screen, just "behind" the arrow.
	var text_pos := (tip - direction * 22.0 - text_size * 0.5).clamp(Vector2(2, 2), size - text_size - Vector2(2, 2))
	draw_string_outline(font, text_pos + Vector2(0, text_size.y * 0.8), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, 3, Color.BLACK)
	draw_string(font, text_pos + Vector2(0, text_size.y * 0.8), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, color)
