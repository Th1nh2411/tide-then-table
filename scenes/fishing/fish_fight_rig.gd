class_name FishFightRig
extends RefCounted
## Rin on his boat on the fishing screen: the lamp, Rin (turning to face
## the hook, leaning with the balance), the hull over his feet, and the rod
## bending towards the hook. Returns the rod tip for the line.

var game: FishFightGame
var _facing: float = 1.0


func _init(owner: FishFightGame) -> void:
	game = owner


## Boat (never rotated: pixel art stays crisp) with Rin leaning against the
## balance; returns the rod tip. Art is drawn at its screen size, 1:1.
func draw(at: Vector2, hook: Vector2) -> Vector2:
	var bob := roundf(sin(game._time * 2.0) * 1.0)
	var origin := (at + Vector2(0, bob)).round()
	# Lamp, then Rin, then the hull over his feet: he stands inside the boat.
	FishFightBoat.draw_lamp(game, game.boat_id, origin, FishFightView.BOAT_SCALE, game._time)
	var feet := FishFightBoat.feet(game.boat_id) + Vector2(roundf(game.balance * 3.0), 0)
	var stance := 0 if game.hooked_index < 0 else 2 if game.tension > 0.6 else 1
	# Rin turns to face the hook (the sheet faces right).
	var offset := hook.x - (origin.x + feet.x * FishFightView.BOAT_SCALE)
	if absf(offset) > 10.0:  # a dead zone under his feet, so he doesn't flicker
		_facing = signf(offset)
	var facing := _facing
	var rin_rect := Rect2(origin + (feet + Vector2(-8, -32)) * FishFightView.BOAT_SCALE, Vector2(16, 32) * FishFightView.BOAT_SCALE)
	if not Art.draw_frame(game, "fishing/rin_side", 3, 1, stance, 0, rin_rect, facing < 0.0):
		game.draw_set_transform(origin, 0.0, Vector2.ONE * FishFightView.BOAT_SCALE)
		_draw_rin_placeholder(feet, stance)
		game.draw_set_transform(Vector2.ZERO)
	FishFightBoat.draw_hull(game, game.boat_id, origin, FishFightView.BOAT_SCALE)
	# The rod from Rin's hands, bending towards the hook with the tension.
	var hands := origin + (feet + Vector2(4.0 * facing, -16)) * FishFightView.BOAT_SCALE
	var toward := (hook - hands).normalized()
	# Held up and forward, swinging towards the hook as the line tightens.
	var rest := Vector2(0.55 * facing, -0.85).angle()
	var angle := lerp_angle(rest, toward.angle(), 0.25 + game.tension * 0.35)
	var straight := hands + Vector2.from_angle(angle) * 64.0
	var bend := straight + toward * game.tension * 18.0
	var points := PackedVector2Array()
	for k in 7:
		var t := k / 6.0
		points.append(hands.lerp(straight, t).lerp(hands.lerp(bend, t), t))
	game.draw_polyline(points, Color("4d2b32"), 3.0)
	game.draw_polyline(points.slice(3), Color("ad7757"), 2.0)
	return points[points.size() - 1]


## `feet`: bottom centre of Rin.
func _draw_rin_placeholder(feet: Vector2, stance: int) -> void:
	feet += Vector2(-4, 0)
	var lean := 1.0 if stance == 2 else 0.0
	game.draw_rect(Rect2(feet + Vector2(1, -10), Vector2(6, 10)), Color("253a5e"))
	game.draw_rect(Rect2(feet + Vector2(lean, -20), Vector2(8, 11)), Color("4f8fba"))
	game.draw_rect(Rect2(feet + Vector2(1 + lean, -26), Vector2(6, 6)), Color("c09473"))
	game.draw_rect(Rect2(feet + Vector2(lean, -28), Vector2(8, 4)), Color("151d28"))  # black hair
