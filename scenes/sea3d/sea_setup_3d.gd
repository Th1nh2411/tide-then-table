class_name SeaSetup3D
extends RefCounted
## One-time wiring of the 3D sea's story bridge (cutscenes), the 2D fishing
## overlay (catch signals, hold) and the cast cinematic + start camera.

const FISHING_OVERLAY := "res://scenes/fishing3d/fishing_overlay_3d.tscn"


static func build_tools(sea: SeaScene3D) -> void:
	var packed := load(FISHING_OVERLAY) as PackedScene
	if packed:
		var overlay := packed.instantiate() as CanvasLayer
		sea.overlay = overlay
		sea.add_child(overlay)
		overlay.connect("catch_detailed", sea._on_catch_detailed)
		overlay.connect("catch_finished", sea._on_catch_finished)
		overlay.connect("rin_fainted", sea._on_rin_fainted)
		overlay.call("bind_hold", sea.hold_ui)
	else:
		push_error("SeaScene3D: fishing overlay unavailable")
	var cinematic := CastCinematic3D.new()
	cinematic.sea = sea
	cinematic.camera = sea.camera
	cinematic.boat_visual = sea.boat_visual
	cinematic.hidden_figure = sea.rin_figure
	sea.cinematic = cinematic
	sea.add_child(cinematic)
	DarkNight3D.attach(sea)  # đêm âm: only when tonight has an omen
	DockOmens3D.build(sea)
	sea.camera.position = sea.boat.position + SeaScene3D.CAMERA_OFFSET
	sea.camera.look_at(sea.boat.position + Vector3(0, .65, -SeaScene3D.CAMERA_LOOK_AHEAD))
