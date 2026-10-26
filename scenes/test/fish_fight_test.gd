extends Node
## Deterministic checks for varied fights and a simple human-like strategy.

var _failures: int = 0


func _ready() -> void:
	_test_variety()
	_test_controls()
	_test_yank_wheel()
	_test_adaptive_player()
	print("fish_fight_test: %s" % ("ALL PASS" if _failures == 0 else "%d FAIL" % _failures))
	get_tree().quit()


func _test_variety() -> void:
	var seen_temperaments: Dictionary = {}
	var seen_incidents: Dictionary = {}
	for seed in range(1, 25):
		var game := _game(seed)
		seen_temperaments[game.temperament] = true
		seen_incidents[game.incident] = true
		game.free()
	_check("casts roll all four temperaments", seen_temperaments.size() == 4)
	_check("casts roll several incidents", seen_incidents.size() >= 3)


func _test_controls() -> void:
	var game := _game(7)
	var start_progress := game.progress
	game.step_fight(0.5, signf(game.fish_position), true)
	_check("holding reels fish closer", game.progress > start_progress)
	game.tension = 0.7
	game.step_fight(0.5, 0.0, false)
	_check("releasing calms the line", game.tension < 0.7)
	game.progress = 0.1
	game.rod_position = game.fish_position
	game.tension = 0.2
	var early_chance := game.yank_chance()
	game.progress = 0.82
	game.rod_position = game.fish_position
	game.tension = 0.3
	var late_chance := game.yank_chance()
	_check("yank chance rises as fish gets closer", late_chance > early_chance)
	game.progress = 0.1
	var tension_before := game.tension
	_check("yank is allowed early", not game.attempt_yank(1.0) and game.tension > tension_before)
	game.progress = 0.82
	game.rod_position = game.fish_position
	game.tension = 0.3
	game.attempt_yank(0.0)
	game.step_fight(0.01, 0.0, false)
	_check("successful yank lands fish", game.get("_done") and game.progress >= 1.0)
	game.free()


func _test_adaptive_player() -> void:
	var wins := 0
	for seed in range(1, 33):
		var game := _game(seed, 0.72)
		for frame in 2400:
			var steer := signf(game.fish_position - game.rod_position)
			var aligned := absf(game.fish_position - game.rod_position) < 0.42
			var reel := aligned and game.tension < 0.66
			game.set("_time", float(game.get("_time")) + 1.0 / 60.0)
			game.step_fight(1.0 / 60.0, steer, reel, game.progress >= 0.82 and game.tension < 0.55)
			if game.get("_done"):
				break
		if game.progress >= 1.0:
			wins += 1
		game.free()
	_check("adaptive player wins most hard fights", wins >= 27)


func _test_yank_wheel() -> void:
	var game := _game(12)
	game.progress = 0.55
	game.start_yank_spin(0.99)
	_check("yank starts a spin before resolving", game.yank_spinning and not game.get("_done"))
	for i in 60:
		game.step_fight(1.0 / 60.0, 0.0, false)
	_check("wheel resolves after slowing down", not game.yank_spinning)
	game.free()


func _game(seed: int, difficulty: float = 0.5) -> FishFightGame:
	var fish: FishData = load("res://data/fish/ca_thu.tres").duplicate()
	fish.difficulty = difficulty
	var game := FishFightGame.new()
	game.random_seed = seed
	game.setup(fish, 1.0)
	return game


func _check(label: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		_failures += 1
