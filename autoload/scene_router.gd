extends CanvasLayer
## Scene switching with a simple fade-to-black. Autoloaded as `SceneRouter`.
## Usage: SceneRouter.go_to("res://scenes/sea/sea_scene.tscn")
## Pass a color to fade through something other than black (e.g. white).

signal scene_changed(scene_path: String)

@export var fade_duration: float = 0.3

var _fade_rect: ColorRect
var _is_transitioning: bool = false


func _ready() -> void:
	# Draw above every other layer so the fade covers the whole game.
	layer = 100
	# Keep fading even if the game tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color.BLACK
	_fade_rect.modulate.a = 0.0
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Ignore mouse so the invisible overlay doesn't block clicks.
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade_rect)
	# Closing the window goes through quit_game() too.
	get_tree().auto_accept_quit = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()


## Quit buttons + window close: stop the sounds and give the audio server a
## few frames to let go of them (a sound still playing at exit leaks).
func quit_game() -> void:
	Sfx.stop_all()
	for i in 3:
		await get_tree().process_frame
	get_tree().quit()


## F11 toggles fullscreen anywhere in the game.
func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.physical_keycode == KEY_F11:
		var fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen
			else DisplayServer.WINDOW_MODE_FULLSCREEN)
		get_viewport().set_input_as_handled()
	elif key and key.pressed and not key.echo and key.physical_keycode == KEY_F7 and OS.is_debug_build():
		_toggle_palette_preview()
		get_viewport().set_input_as_handled()


## F7 (debug): see the whole game in the art palette (PalettePreview).
func _toggle_palette_preview() -> void:
	var preview := get_node_or_null("PalettePreview")
	if preview:
		preview.queue_free()
		return
	preview = PalettePreview.new()
	preview.name = "PalettePreview"
	add_child(preview)


func go_to(scene_path: String, fade_color: Color = Color.BLACK) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_fade_rect.color = fade_color
	# Block input during the transition so buttons can't be double-clicked.
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	await _fade_to(1.0)
	# A pause left over by the old scene (a cutscene / panel cut short) must
	# never carry into the new one: that would freeze the game for good.
	get_tree().paused = false
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("SceneRouter: failed to load %s (error %d)" % [scene_path, error])
	await _fade_to(0.0)

	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_transitioning = false
	scene_changed.emit(scene_path)


func _fade_to(target_alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", target_alpha, fade_duration)
	await tween.finished
