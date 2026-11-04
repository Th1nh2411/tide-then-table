class_name SeaHud3D
extends RefCounted
## HUD (SeaHudView3D: icon chips, the dock prompt, the shared subtitles) and
## the pause menu of the 3D sea. No markers or place names: the way home is
## in the world (SeaLandmarks3D). No how-to pointers: ông Tám tells Rin about
## the bubbles at dawn (data/story/ong_tam.tres).
## Host (SeaScene3D) fields written: hud_view, message.

static func build_hud(sea: SeaScene3D) -> void:
	var layer := CanvasLayer.new()
	sea.add_child(layer)
	sea.hud_view = SeaHudView3D.new()
	layer.add_child(sea.hud_view)
	# The current Rin's line (SeaScene3D._say queue); the view shows it on
	# its speech strip.
	sea.message = Label.new()
	sea.message.visible = false
	layer.add_child(sea.message)

static func build_shared_ui(sea: SeaScene3D) -> void:
	var pause := load("res://scenes/ui/pause_menu.tscn") as PackedScene
	if pause:
		sea.add_child(pause.instantiate())

static func update(sea: SeaScene3D) -> void:
	sea._next_line()
	sea.hud_view.refresh(sea)
