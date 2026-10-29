extends Node
## Cast cinematic: input locked while it plays, then the 2D minigame opens
## with exactly the shoal's fish, and control returns afterwards.

var failures: int = 0

func check(value: bool, label: String) -> void:
	print("PASS " + label if value else "FAIL " + label)
	if not value:
		failures += 1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.reset()
	var sea: Node = (load("res://scenes/sea3d/sea_scene_3d.tscn") as PackedScene).instantiate()
	add_child(sea)
	sea.set_physics_process(false)
	await get_tree().process_frame
	sea.new_catch_card.queue_free()
	sea.new_catch_card = null
	var shoal: SeaShoals3D.Shoal = sea.shoals[sea._nearest_school_index()]
	shoal.fish_left = 4
	shoal.max_fish = 4
	sea.boat.position = shoal.pos
	sea.boat.velocity = Vector3.ZERO
	var overlay: FishingOverlay3D = sea.overlay
	overlay._minigame.result_seconds = 0.01
	sea._try_fish()
	check(sea.fishing and sea.cinematic.playing and not overlay.active, "cast cinematic starts and locks input before the minigame")
	var actor: PersonRig3D = sea.cinematic.get("_rig")
	var visual := actor.get_node("RinPilot") as RinPilotVisual
	check(visual.animation.assigned_animation == "Cast", "Gameplay cinematic samples the exported Cast animation")
	var frames := 0
	while not overlay.active and frames < 600:
		await get_tree().process_frame
		frames += 1
		if frames == 25 and OS.get_cmdline_user_args().has("--capture-cast"):
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://build/rin_cast/gameplay.png")
	check(overlay.active and not sea.cinematic.playing and frames < 400, "cast cinematic completes and hands control to the minigame")
	check(overlay._minigame._game is FishFightGame and (overlay._minigame._game as FishFightGame).school_size == 4,
		"minigame shows exactly the shoal's fish")
	check(shoal.fish_left == 3, "shoal loses one fish per cast")
	overlay._minigame._game._finish(true, true)
	frames = 0
	while (overlay.active or sea.fishing) and frames < 600:
		await get_tree().process_frame
		frames += 1
	check(not sea.fishing and not get_tree().paused and sea.cinematic.wipe_progress == 0.0,
		"return transition ends and boat control resumes")
	sea.queue_free()
	await get_tree().process_frame
	get_tree().quit(1 if failures else 0)
