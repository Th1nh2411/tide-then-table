class_name FishSchoolPhysics
extends RefCounted
## Movement of the school on the fishing screen, in arena units (x -1..1,
## y 0 surface..1 bottom): fish ease into turns instead of flipping, drift
## up and down a little, bounce off the sides, the surface band and the
## seabed, and push each other apart when they bump (head-on fish turn
## back). A free hook brushed by a fish gets nudged. Pure math on the
## school dictionaries; FishFightGame owns the numbers.

## Arena units: a fish's body radius at size 1 (bumps), how hard bumps push.
const BODY_RADIUS := 0.07
const PUSH := 0.6
const TOP := 0.22
const BOTTOM := 0.96


## Turn rate (units/s²) and up/down drift (units/s) come from the game.
static func step(school: Array[Dictionary], hooked: int, delta: float, time: float,
		turn_accel: float, drift: float) -> Array[Vector2]:
	var bumps: Array[Vector2] = []
	for i in school.size():
		var entry: Dictionary = school[i]
		var pos: Vector2 = entry["pos"]
		var speed: float = entry["speed"]
		var direction: float = entry["dir"]
		if i == hooked:  # big fish pull harder, in slow surges
			speed *= (1.0 + float(entry["size"]) * 0.35) * (1.0 + 0.3 * sin(time * 1.3 + float(entry["phase"])))
		var vx: float = entry.get("vx", direction * speed)
		vx = move_toward(vx, direction * speed, turn_accel * delta)
		pos.x += vx * delta
		# Start turning before the wall so the fish slows and swings round.
		if absf(pos.x) > 0.86 and signf(pos.x) == direction:
			entry["dir"] = -direction
		if absf(pos.x) >= 1.0:
			pos.x = clampf(pos.x, -1.0, 1.0)
			vx = -vx * 0.4
		if i != hooked:
			pos.y += sin(time * 0.8 + float(entry["phase"]) * 3.0) * drift * delta
			if pos.y < TOP or pos.y > BOTTOM:
				pos.y = clampf(pos.y, TOP, BOTTOM)
		entry["vx"] = vx
		entry["pos"] = pos
	for i in school.size():
		for j in range(i + 1, school.size()):
			if _bump(school[i], school[j], i == hooked, j == hooked, delta):
				bumps.append(((school[i]["pos"] as Vector2) + (school[j]["pos"] as Vector2)) * 0.5)
	return bumps


## Two overlapping fish slide apart; facing each other, the free one turns.
static func _bump(a: Dictionary, b: Dictionary, a_hooked: bool, b_hooked: bool, delta: float) -> bool:
	var pa: Vector2 = a["pos"]
	var pb: Vector2 = b["pos"]
	var reach := BODY_RADIUS * (float(a["size"]) + float(b["size"]))
	var gap := pb - pa
	var distance := gap.length()
	if distance >= reach:
		return false
	var away := gap / distance if distance > 0.0001 else Vector2.RIGHT
	var push := away * (reach - distance) * PUSH
	# The hooked fish is held by the line: only the other one moves.
	if not a_hooked:
		a["pos"] = pa - push * (0.5 if not b_hooked else 1.0)
	if not b_hooked:
		b["pos"] = pb + push * (0.5 if not a_hooked else 1.0)
	var head_on := float(a["dir"]) != float(b["dir"]) and signf(gap.x) == float(a["dir"])
	if head_on:
		if not a_hooked:
			a["dir"] = -float(a["dir"])
		elif not b_hooked:
			b["dir"] = -float(b["dir"])
	return delta > 0.0


## A fish brushing the free hook knocks it sideways (x velocity added).
static func hook_nudge(school: Array[Dictionary], hook: Vector2) -> float:
	var kick := 0.0
	for entry: Dictionary in school:
		var pos: Vector2 = entry["pos"]
		if pos.distance_to(hook) < BODY_RADIUS * float(entry["size"]):
			kick += float(entry.get("vx", 0.0)) * 0.5
	return kick
