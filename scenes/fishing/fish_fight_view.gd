class_name FishFightView
extends RefCounted
## Draws FishFightGame full screen, side view: the sea (FishFightBackdrop),
## Rin's boat on the surface (Rin leans with the balance), with a rod that
## bends with the line tension, the line, bobber and hook, the school
## (sprites "fish/<id>", a dark shadow for species not in the Dex yet),
## splashes and bubbles, the daze vignette, and the readouts
## (FishFightGauges). After a catch the fish flies out of the water into
## the boat. Art hooks: the boat per BoatData id (FishFightBoat), "fishing/rin_side"
## (sheet 3x1 of 16x32: waiting, reeling, straining).

const INK := Color("090a14")
const SHADOW := Color(0.05, 0.08, 0.12, 0.92)
const MARGIN := 44.0
const FISH_WIDTH := 46.0
## Boat and Rin are drawn at 2x (Rin 32x64 on screen).
const BOAT_SCALE := 2.0
const LAND_SECONDS := 0.7
const RING_SECONDS := 0.35

var game: FishFightGame
var _particles: Array[Dictionary] = []
var _bubble_clock: float = 0.0
var _landed_clock: float = -1.0
var _land_from := Vector2.ZERO
var _backdrop_cache: Dictionary = {}
var _rig: FishFightRig
var _line := FishFightLine.new()
var _frame_delta: float = 1.0 / 60.0
var _bump_clock: float = 0.0


func _init(owner: FishFightGame) -> void:
	game = owner
	_rig = FishFightRig.new(owner)
	game.tugged.connect(func() -> void: splash(hook_screen(), 6))
	game.boat_bumped.connect(func() -> void: splash(boat_screen() + Vector2(signf(game.boat_position) * 50.0, 0), 8))
	game.fish_bumped.connect(_on_fish_bumped)


func tick(delta: float) -> void:
	_frame_delta = delta
	_bump_clock = maxf(_bump_clock - delta, 0.0)
	for p: Dictionary in _particles:
		p["life"] = float(p["life"]) - delta
		var vel: Vector2 = p["vel"]
		if p["kind"] == "drop":
			vel.y += 260.0 * delta
		p["vel"] = vel
		p["pos"] = (p["pos"] as Vector2) + vel * delta
	_particles = _particles.filter(func(p: Dictionary) -> bool: return float(p["life"]) > 0.0)
	_bubble_clock -= delta
	if _bubble_clock <= 0.0 and not game._done:
		_bubble_clock = 0.35 if game.hooked_index >= 0 else 0.8
		_particles.append({"kind": "bubble", "pos": hook_screen() + Vector2(randf_range(-3, 3), 0),
			"vel": Vector2(randf_range(-4, 4), -22.0), "life": 1.6})
	if _landed_clock >= 0.0:
		var before := _landed_clock
		_landed_clock += delta
		if before < LAND_SECONDS and _landed_clock >= LAND_SECONDS:
			Sfx.play("flop")  # slaps onto the deck


## The caught fish leaps out of the water into the boat.
func land() -> void:
	_landed_clock = 0.0
	_land_from = hook_screen()
	splash(Vector2(_land_from.x, surface()), 10)
	Sfx.play("splash")


## Fish knocking together: a spark and a puff of bubbles (at most 4 a second).
func _on_fish_bumped(at: Vector2) -> void:
	if _bump_clock > 0.0:
		return
	_bump_clock = 0.25
	var where := to_screen(at)
	_particles.append({"kind": "spark", "pos": where, "vel": Vector2.ZERO, "life": 0.18})
	for i in 3:
		_particles.append({"kind": "bubble", "pos": where + Vector2(randf_range(-4, 4), randf_range(-3, 3)),
			"vel": Vector2(randf_range(-6, 6), -18.0), "life": 0.9})


## A bright ring spreading from `at` (the bite).
func ring(at: Vector2) -> void:
	_particles.append({"kind": "ring", "pos": at, "vel": Vector2.ZERO, "life": RING_SECONDS})


func splash(at: Vector2, count: int) -> void:
	var y := surface()
	for i in count:
		_particles.append({"kind": "drop", "pos": Vector2(at.x + randf_range(-6, 6), y),
			"vel": Vector2(randf_range(-40, 40), randf_range(-90, -40)), "life": 0.6})


func surface() -> float:
	return FishFightBackdrop.surface_y(game.size)


func to_screen(pos: Vector2) -> Vector2:
	var top := surface() + 16.0
	var bottom := game.size.y - 62.0
	return Vector2(lerpf(MARGIN, game.size.x - MARGIN, (pos.x + 1.0) * 0.5), lerpf(top, bottom, pos.y)).round()


func hook_screen() -> Vector2:
	return to_screen(game.hook_position)


func boat_screen() -> Vector2:
	return Vector2(roundf(lerpf(MARGIN, game.size.x - MARGIN, (game.boat_position + 1.0) * 0.5)), surface())


func draw() -> void:
	var size := game.size
	var boat := boat_screen()
	FishFightBackdrop.draw(game, size, game.zone, game._time, boat.x + (FishFightBoat.spec(game.boat_id)["lamp"] as Vector2).x * BOAT_SCALE, _backdrop_cache)
	for i in game.school.size():
		if i != game.hooked_index or _landed_clock < 0.0:
			_draw_fish(i)
	var tip := _rig.draw(boat, hook_screen())
	if _landed_clock < 0.0:
		_draw_line(tip)
	else:
		_draw_landing(boat)
	_draw_particles()
	_draw_daze(size, boat)
	FishFightGauges.draw(game, game, size)


func _draw_fish(i: int) -> void:
	var entry: Dictionary = game.school[i]
	var hooked := i == game.hooked_index
	var pos := to_screen(entry["pos"])
	var scale: float = entry["size"]
	var facing: float = entry["dir"]
	var rotation := sin(game._time * 3.0 + float(entry["phase"])) * 0.06
	if hooked:  # head up towards the line, thrashing harder with tension
		facing = signf(boat_screen().x - pos.x) if absf(boat_screen().x - pos.x) > 2.0 else facing
		rotation = -0.55 * facing + sin(game._time * 28.0) * (0.08 + game.tension * 0.2)
	var tint := _fish_tint(pos.y)
	_draw_fish_sprite(pos, rotation, facing, scale, tint)
	# Scales flash now and then when the fish swims through the lamp light.
	if _known() and _in_light(pos) and sin(game._time * 5.0 + float(entry["phase"]) * 7.0) > 0.93:
		_glint(pos + Vector2(facing * FISH_WIDTH * scale * 0.2, -3), 1.0)


## Inside the boat lamp's cone (see FishFightBackdrop._draw_light).
func _in_light(pos: Vector2) -> bool:
	var lamp_x := boat_screen().x + (FishFightBoat.spec(game.boat_id)["lamp"] as Vector2).x * BOAT_SCALE
	return absf(pos.x - lamp_x) < 20.0 + (pos.y - surface()) * 0.6


## A tiny white star; `size` 1 = 3 px cross, 2 = 5 px.
func _glint(at: Vector2, size: float) -> void:
	var arm := roundf(maxf(size, 0.5))
	var color := Color(1, 1, 0.92, clampf(size, 0.0, 1.0))
	game.draw_rect(Rect2(at.round() - Vector2(arm, 0), Vector2(arm * 2 + 1, 1)), color)
	game.draw_rect(Rect2(at.round() - Vector2(0, arm), Vector2(1, arm * 2 + 1)), color)


func _fish_tint(y: float) -> Color:
	if not _known():
		return SHADOW
	var depth := clampf((y - surface()) / (game.size.y - surface()), 0.0, 1.0)
	return game._tint(Color.WHITE).lerp(Color(0.35, 0.5, 0.7), depth * 0.45)


func _known() -> bool:
	return int(GameState.caught_species.get(game.fish.id, 0)) > 0


func _draw_fish_sprite(pos: Vector2, rotation: float, facing: float, scale: float, tint: Color) -> void:
	var tex := Art.texture("fish/" + game.fish.id)
	var width := FISH_WIDTH * scale * (0.7 if game.fish.id == "muc" else 1.0)
	var aspect := float(tex.get_height()) / tex.get_width() if tex else 0.45
	var rect := Rect2(Vector2(-width, -width * aspect) * 0.5, Vector2(width, width * aspect))
	var squash := 1.0 + sin(game._time * 9.0 + pos.x) * 0.04
	game.draw_set_transform(pos, rotation, Vector2(facing * squash, 1.0))
	if tex:
		game.draw_texture_rect(tex, rect, false, tint)
	else:
		FishPortrait.draw_shape(game, game.fish.id, rect, game.fish.color * tint, (game.fish.color * tint).darkened(0.3))
	game.draw_set_transform(Vector2.ZERO)


func _draw_line(tip: Vector2) -> void:
	var hook := hook_screen()
	var color := Color("f2d98a").lerp(Color("e0302b"), clampf((game.tension - 0.55) * 2.2, 0.0, 1.0))
	# Soft rope: sags while slack (a free hook counts as a little tension: the bait's weight).
	var pull := game.tension if game.hooked_index >= 0 else 0.12
	_line.step(tip, hook, pull, surface(), _frame_delta)
	game.draw_polyline(_line.points, color, 1.0)
	if game.hooked_index < 0:  # bobber where the line meets the water
		var crossing: Variant = _line.surface_crossing(surface())
		if crossing != null:
			var at: Vector2 = (crossing as Vector2) + Vector2(0, roundf(sin(game._time * 3.0)))
			game.draw_circle(at, 2.5, Color("e0302b"))
			game.draw_rect(Rect2(at + Vector2(-2, -1), Vector2(5, 1)), Color("ebede9"))
	# Hook and bait.
	game.draw_arc(hook + Vector2(0, 2), 2.5, 0.0, PI, 6, Color("c7cfcc"), 1.0)
	if game.hooked_index < 0:
		game.draw_rect(Rect2(hook + Vector2(-1, 2), Vector2(3, 2)), Color("cf573c"))
	if sin(game._time * 4.0) > 0.9:  # the hook catches the lamp light
		_glint(hook + Vector2(2, 0), 1.0)
	if game.hooked_index < 0 and game._bite_candidate >= 0:
		game.draw_arc(hook, 9.0, -PI * 0.5, -PI * 0.5 + TAU * game.bite_progress(), 20, Color("a8ca58"), 2.0)


## The fish arcs from the water onto the deck.
func _draw_landing(boat: Vector2) -> void:
	var t := clampf(_landed_clock / LAND_SECONDS, 0.0, 1.0)
	var to := boat + Vector2(0, -30)
	var leap := 50.0 + maxf(_land_from.y - surface(), 0.0) * 0.5
	var at := _land_from.lerp(to, t) + Vector2(0, -sin(t * PI) * leap)
	var entry: Dictionary = game.school[game.hooked_index]
	_draw_fish_sprite(at.round(), t * TAU * 1.5, 1.0, float(entry["size"]), game._tint(Color.WHITE) if _known() else SHADOW)


func _draw_particles() -> void:
	for p: Dictionary in _particles:
		var pos: Vector2 = (p["pos"] as Vector2).round()
		if p["kind"] == "spark":
			_glint(pos, float(p["life"]) / 0.18 * 2.0)
		elif p["kind"] == "ring":
			var life := float(p["life"]) / RING_SECONDS
			game.draw_arc(pos, 4.0 + (1.0 - life) * 22.0, 0.0, TAU, 24, Color(0.95, 1.0, 0.8, life), 2.0)
		elif p["kind"] == "drop":
			game.draw_rect(Rect2(pos, Vector2(1, 2)), Color(0.85, 0.95, 1.0, 0.9))
		elif pos.y > surface():
			game.draw_arc(pos, 1.5, 0.0, TAU, 8, Color(0.75, 0.9, 1.0, 0.6), 1.0)


## Rin's daze: dark purple edges, stars round his head when it gets high.
func _draw_daze(size: Vector2, boat: Vector2) -> void:
	if game.stun < 0.05:
		return
	for i in 4:
		var band := 8.0 * (i + 1)
		var color := Color(0.16, 0.08, 0.2, game.stun * 0.12)
		game.draw_rect(Rect2(0, 0, size.x, band), color)
		game.draw_rect(Rect2(0, size.y - band, size.x, band), color)
		game.draw_rect(Rect2(0, 0, band, size.y), color)
		game.draw_rect(Rect2(size.x - band, 0, band, size.y), color)
	if game.stun > 0.45:
		for i in 3:
			var angle := game._time * 4.0 + i * TAU / 3.0
			var head := (FishFightBoat.feet(game.boat_id) + Vector2(0, -35)) * BOAT_SCALE
			var at := boat + head + Vector2(cos(angle) * 12.0, sin(angle) * 4.0)
			game.draw_rect(Rect2(at.round(), Vector2(2, 2)), Color("f2d98a"))
