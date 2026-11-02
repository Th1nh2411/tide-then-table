extends Node
## Standalone test for ReelLogic (run with F6): bite timing (sooner at a
## shoal), the hook window, the reel fight (holding all the time snaps the
## line, easing off when the line is tight lands even the strongest fish,
## never reeling never lands), stronger fish fight harder.

const STEP := 1.0 / 60.0

var _failures := 0


func _ready() -> void:
	var tuning := ReelTuning.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	_bites(tuning, rng)
	_window(tuning)
	_strength()
	_fights(tuning)
	print("REEL LOGIC TEST ", "PASS" if _failures == 0 else "FAIL")
	get_tree().quit(1 if _failures else 0)


func _bites(tuning: ReelTuning, rng: RandomNumberGenerator) -> void:
	var open_ok := true
	var shoal_ok := true
	var open_sum := 0.0
	var shoal_sum := 0.0
	for i in range(400):
		var open := ReelLogic.bite_delay(tuning, rng, false)
		var shoal := ReelLogic.bite_delay(tuning, rng, true)
		open_ok = open_ok and open >= tuning.bite_min and open <= tuning.bite_max
		shoal_ok = shoal_ok and shoal < tuning.bite_max * tuning.shoal_bite_scale + 0.001
		open_sum += open
		shoal_sum += shoal
	_check("bites come after 3-8 s", open_ok and tuning.bite_min == 3.0 and tuning.bite_max == 8.0)
	_check("bites come sooner at a shoal", shoal_ok and shoal_sum < open_sum * 0.6)


func _window(tuning: ReelTuning) -> void:
	_check("click inside the window hooks", ReelLogic.in_window(tuning, 0.0) and ReelLogic.in_window(tuning, 1.1))
	_check("click after ~1.2 s is too late", not ReelLogic.in_window(tuning, 1.3))


func _strength() -> void:
	var small := FishData.new()
	small.difficulty = 0.3
	var rare := FishData.new()
	rare.difficulty = 0.3
	rare.is_aberrant = true
	_check("bigger fish fight harder", ReelLogic.strength_of(small, 1.5) > ReelLogic.strength_of(small, 0.8))
	_check("aberrant fish fight harder", ReelLogic.strength_of(rare, 1.0) > ReelLogic.strength_of(small, 1.0))


func _fights(tuning: ReelTuning) -> void:
	var snapped := 0
	var landed_smart := 0
	var never := 0
	var times_weak := 0.0
	var times_strong := 0.0
	for seed_value in range(20):
		if _fight(tuning, 0.5, 9.0, seed_value, "hold")[0] == ReelLogic.Outcome.SNAPPED:
			snapped += 1
		var strong: Array = _fight(tuning, 1.0, tuning.cast_max, seed_value, "smart")
		var weak: Array = _fight(tuning, 0.2, tuning.cast_max, seed_value, "smart")
		if strong[0] == ReelLogic.Outcome.LANDED and weak[0] == ReelLogic.Outcome.LANDED:
			landed_smart += 1
		times_strong += float(strong[1])
		times_weak += float(weak[1])
		if _fight(tuning, 0.5, 9.0, seed_value, "never")[0] != ReelLogic.Outcome.LANDED:
			never += 1
	print("    mean fight: weak %.1f s, strong %.1f s" % [times_weak / 20.0, times_strong / 20.0])
	_check("holding the reel all the time snaps the line", snapped == 20)
	_check("easing off when tight lands even the strongest fish", landed_smart == 20)
	_check("a strong fish takes longer than a weak one", times_strong > times_weak)
	_check("fights last a few seconds, not minutes", times_weak / 20.0 > 3.0 and times_strong / 20.0 < 40.0)
	_check("never reeling never lands", never == 20)


## [outcome, seconds]. "hold" = always reeling, "smart" = reel while the line
## is not too tight (the bot's policy), "never" = never reel.
func _fight(tuning: ReelTuning, strength: float, distance: float, seed_value: int, policy: String) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var reel := ReelLogic.new(tuning, strength, distance, rng)
	var t := 0.0
	while t < 60.0:
		var held := policy == "hold" or (policy == "smart" and reel.tension < (0.45 if reel.running else 0.75))
		var outcome := reel.step(STEP, held)
		t += STEP
		if outcome != ReelLogic.Outcome.FIGHTING:
			return [outcome, t]
	return [ReelLogic.Outcome.FIGHTING, t]


func _check(label: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		_failures += 1
