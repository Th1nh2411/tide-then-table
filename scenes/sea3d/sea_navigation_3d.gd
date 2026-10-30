extends Control
## Project map destinations through the real 3D camera.

var world: Node3D
var camera: Camera3D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(_delta: float) -> void:
	queue_redraw()

func screen_point(pos: Vector3) -> Vector2:
	var area := Rect2(Vector2(24, 110), get_viewport_rect().size - Vector2(48, 182))  # clear of the HUD + speech strip
	var screen := camera.unproject_position(pos + Vector3.UP * 0.4)
	var center := area.get_center()
	var direction := screen - center
	if camera.is_position_behind(pos):
		direction = -direction
	if direction.is_zero_approx():
		direction = Vector2.DOWN
	if not camera.is_position_behind(pos) and area.has_point(screen):
		return screen
	var unit := direction.normalized()
	var reach: float = minf(area.size.x * 0.5 / maxf(absf(unit.x), 0.001), area.size.y * 0.5 / maxf(absf(unit.y), 0.001))
	return center + unit * reach

func _draw() -> void:
	if not is_instance_valid(world) or not is_instance_valid(camera):
		return
	if bool(world.get("fishing")) or bool(world.get("ending")) or get_tree().paused:
		return
	var phone := world.get("phone_app") as CanvasLayer
	var hold := world.get("hold_ui") as CanvasLayer
	if (phone and phone.visible) or (hold and hold.visible):
		return
	var targets: Array = world.call("navigation_targets")
	var font := ThemeDB.fallback_font
	var boat := world.get("boat") as Node3D
	for target: Dictionary in targets:
		var pos: Vector3 = target["pos"]
		var color := Color(str(target["color"]))
		var projected := camera.unproject_position(pos + Vector3.UP * 0.4)
		var at := screen_point(pos)
		var edge: bool = camera.is_position_behind(pos) or projected.distance_to(at) > 1.0
		if edge:
			var direction := (at - Vector2(get_viewport_rect().size.x * 0.5, get_viewport_rect().size.y * 0.5)).normalized()
			var side := direction.orthogonal() * 4.0
			draw_colored_polygon(PackedVector2Array([at, at - direction * 9.0 + side, at - direction * 9.0 - side]), color)
		else:
			draw_arc(at, 7.0, 0.0, TAU, 16, color, 1.5)
		var label: String = str(target["label"])
		if edge:
			label += " %dm" % roundi(boat.position.distance_to(pos))
		var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9)
		var text_pos := (at + Vector2(10, -9)).clamp(Vector2(4, 102), get_viewport_rect().size - text_size - Vector2(4, 66))
		draw_string_outline(font, text_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, 3, Color("172038"))
		draw_string(font, text_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, color)
