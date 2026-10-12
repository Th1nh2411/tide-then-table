extends Node2D
## New Game intro: Rin's rented room in the city, months after the startup
## failed. Plays the `intro` cutscene (lying in bed, remembering Bảo's
## noodles, calling him to open the restaurant), then the first night at sea.
## The room is a placeholder drawing (640x360); markers under
## CutsceneMarkers place the actors.

const SEA_SCENE_PATH: String = "res://scenes/sea/sea_scene.tscn"

@export var intro: Cutscene

@onready var _player: CutscenePlayer = $CutscenePlayer


func _ready() -> void:
	Sfx.ambience("")
	await get_tree().process_frame  # let the router's fade-in start first
	if intro:
		await _player.play(intro)
	SceneRouter.go_to(SEA_SCENE_PATH)


func _draw() -> void:
	# Wall and floor.
	draw_rect(Rect2(0, 0, 640, 170), Color(0.42, 0.45, 0.5))
	draw_rect(Rect2(0, 170, 640, 190), Color(0.5, 0.38, 0.28))
	for x in range(0, 640, 40):
		draw_line(Vector2(x, 170), Vector2(x - 60, 360), Color(0.44, 0.33, 0.24), 1.0)
	draw_rect(Rect2(0, 166, 640, 6), Color(0.3, 0.3, 0.33))
	# Window: the city at night.
	draw_rect(Rect2(372, 40, 156, 104), Color(0.25, 0.22, 0.2))
	draw_rect(Rect2(380, 48, 140, 88), Color(0.08, 0.1, 0.2))
	for i in 14:
		var bx := 384.0 + i * 10.0
		var top := 90.0 + float((i * 37) % 30)
		draw_rect(Rect2(bx, top, 9, 136 - top), Color(0.12, 0.13, 0.2))
		if i % 3 != 1:
			draw_rect(Rect2(bx + 3, top + 8, 2, 2), Color(1.0, 0.85, 0.4))
	draw_line(Vector2(450, 48), Vector2(450, 136), Color(0.25, 0.22, 0.2), 3.0)
	# Old startup poster, peeling.
	draw_rect(Rect2(60, 50, 70, 50), Color(0.85, 0.85, 0.8))
	draw_rect(Rect2(66, 56, 58, 10), Color(0.2, 0.5, 0.75))
	draw_string(ThemeDB.fallback_font, Vector2(66, 82), "Rin's Catch", HORIZONTAL_ALIGNMENT_LEFT, -1, 8,
		Color(0.2, 0.2, 0.25))
	draw_colored_polygon(PackedVector2Array([Vector2(130, 50), Vector2(118, 50), Vector2(130, 62)]),
		Color(0.42, 0.45, 0.5))
	# Bed.
	draw_rect(Rect2(76, 196, 182, 40), Color(0.85, 0.85, 0.9))
	draw_rect(Rect2(76, 236, 182, 16), Color(0.45, 0.3, 0.2))
	draw_rect(Rect2(84, 200, 40, 16), Color(1, 1, 1))  # pillow
	# Desk with the laptop and the last pack of noodles.
	draw_rect(Rect2(500, 196, 124, 10), Color(0.55, 0.4, 0.25))
	draw_rect(Rect2(508, 206, 6, 46), Color(0.45, 0.3, 0.2))
	draw_rect(Rect2(610, 206, 6, 46), Color(0.45, 0.3, 0.2))
	draw_rect(Rect2(520, 180, 34, 16), Color(0.25, 0.25, 0.28))  # laptop
	draw_rect(Rect2(523, 183, 28, 10), Color(0.35, 0.55, 0.75))
	draw_rect(Rect2(574, 186, 26, 10), Color(0.9, 0.35, 0.2))  # noodle pack
	draw_string(ThemeDB.fallback_font, Vector2(576, 194), "MÌ", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(1, 0.9, 0.4))
	# Empty noodle cups on the floor.
	for at: Vector2 in [Vector2(330, 246), Vector2(352, 254), Vector2(220, 256)]:
		draw_rect(Rect2(at, Vector2(12, 12)), Color(0.95, 0.95, 0.9))
		draw_rect(Rect2(at, Vector2(12, 3)), Color(0.85, 0.3, 0.2))
