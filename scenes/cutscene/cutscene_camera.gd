class_name CutsceneCamera
extends Camera2D
## CutscenePlayer's camera: takes over from the scene's camera (or the plain
## view in scenes without one), glides between markers and hands back.
## Markers are children of `markers`, or "@group" (the first node in that
## group, e.g. the boat wherever it is at sea), optionally shifted
## "@boat+18,-6".

var markers: Node2D

var _previous: Camera2D


func _ready() -> void:
	# Off until a cutscene plays: in a scene without a camera (restaurant) an
	# enabled Camera2D becomes current by itself and shifts the whole view.
	enabled = false


func begin() -> void:
	_previous = get_viewport().get_camera_2d()
	if _previous:
		global_position = _previous.get_screen_center_position()
		zoom = _previous.zoom
	else:
		# UI scenes (restaurant) have no camera: start on the plain view.
		global_position = get_viewport_rect().size * 0.5
		zoom = Vector2.ONE
	enabled = true
	make_current()


func end() -> void:
	if _previous and is_instance_valid(_previous):
		_previous.make_current()
	else:
		enabled = false


func move(target: Vector2, seconds: float, to_zoom: float, instant: bool) -> void:
	if instant or seconds <= 0.0:
		global_position = target
		zoom = Vector2(to_zoom, to_zoom)
		return
	var tween := create_tween().set_parallel()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "global_position", target, seconds)
	tween.tween_property(self, "zoom", Vector2(to_zoom, to_zoom), seconds)
	await tween.finished


func marker(marker_name: String) -> Vector2:
	var node: Node2D = null
	var offset := Vector2.ZERO
	if marker_name.begins_with("@"):
		var parts := marker_name.substr(1).split("+")
		node = get_tree().get_first_node_in_group(parts[0]) as Node2D
		if parts.size() > 1:
			var xy := parts[1].split(",")
			offset = Vector2(float(xy[0]), float(xy[1]) if xy.size() > 1 else 0.0)
	elif markers:
		node = markers.get_node_or_null(marker_name) as Node2D
	if node == null:
		push_warning("Cutscene marker '%s' not found" % marker_name)
		return global_position
	return node.global_position + offset
