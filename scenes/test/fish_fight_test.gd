extends Node
## Deterministic checks for free hook control, hauling, gamble, and fainting.

var _failures: int = 0


func _ready() -> void:
	_test_school_and_free_hook()
	_test_haul_and_yank()
	_test_faint()
	_test_yank_wheel()
	_test_adaptive_player()
	print("fish_fight_test: %s" % ("ALL PASS" if _failures == 0 else "%d FAIL" % _failures))
	get_tree().quit()


func _test_school_and_free_hook() -> void:
	var game := _game(3)
	_check("one cast contains many fish", game.school.size() == game.school_size)
	var sizes: Dictionary = {}
	for entry: Dictionary in game.school:
		sizes[roundi(float(entry["size"]) * 100.0)] = true
	_check("fish in the school have different sizes", sizes.size() >= 3)
	var start_depth := game.hook_position.y
	game.step_fight(0.5, 1.0, 1.0)
	_check("A/D moves boat and S lowers hook", game.boat_position > 0.0 and game.hook_position.y > start_depth)
	_place_hook_on(game, 0)
	game.step_fight(0.01, 0.0, 0.0, true)
	_check("Space hooks the aimed fish", game.hooked_index == 0)
	game.free()


func _test_haul_and_yank() -> void:
	var game := _game(7)
	_hook_first(game)
	var start_progress := game.progress
	game.step_fight(0.5, signf(_fish_x(game) - game.boat_position), -1.0)
	_check("W reels hooked fish upward", game.progress > start_progress)
	game.tension = 0.7
	game.step_fight(0.5, 0.0, 1.0)
	_check("S gives slack and calms line", game.tension < 0.7)
	game.boat_position = _fish_x(game)
	_set_fish_depth(game, 0.85)
	var early := game.yank_green_chance()
	_set_fish_depth(game, 0.2)
	var late := game.yank_green_chance()
	_check("green chance grows as fish nears surface", late > early)
	var stun_before := game.stun
	_check("red yank risks Rin", game.resolve_yank(1.0) == FishFightGame.YankResult.RED and game.stun > stun_before)
	game.resolve_yank(0.0)
	_check("green yank lands fish", game.get("_done") and game.progress >= 1.0)
	game.free()


func _test_faint() -> void:
	var game := _game(9, 0.7)
	_hook_first(game)
	var fainted: Array[bool] = [false]
	game.rin_fainted.connect(func() -> void: fainted[0] = true)
	game.stun = 1.0
	game.step_fight(0.02, 0.0, 0.0)
	_check("full stun makes Rin faint", fainted[0] and game.get("_done"))
	game.free()


func _test_yank_wheel() -> void:
	var game := _game(12)
	_hook_first(game)
	game.start_yank_spin(0.99)
	_check("yank starts a spin before resolving", game.yank_spinning and not game.get("_done"))
	for i in 60:
		game.step_fight(1.0 / 60.0, 0.0, 0.0)
	_check("wheel resolves after slowing down", not game.yank_spinning)
	game.free()


func _test_adaptive_player() -> void:
	var wins := 0
	for seed in range(1, 33):
		var game := _game(seed, 0.72)
		_hook_first(game)
		for frame in 2400:
			var steer := signf(_fish_x(game) - game.boat_position)
			var depth := -1.0 if game.tension < 0.68 else 1.0
			game.set("_time", float(game.get("_time")) + 1.0 / 60.0)
			game.step_fight(1.0 / 60.0, steer, depth)
			if game.get("_done"):
				break
		if game.progress >= 0.96:
			wins += 1
		game.free()
	_check("adaptive player wins most hard fights", wins >= 27)


func _hook_first(game: FishFightGame) -> void:
	_place_hook_on(game, 0)
	game.step_fight(0.01, 0.0, 0.0, true)


func _place_hook_on(game: FishFightGame, index: int) -> void:
	var pos: Vector2 = game.school[index]["pos"]
	game.boat_position = pos.x
	game.hook_position = pos


func _fish_x(game: FishFightGame) -> float:
	return (game.school[game.hooked_index]["pos"] as Vector2).x


func _set_fish_depth(game: FishFightGame, depth: float) -> void:
	var entry: Dictionary = game.school[game.hooked_index]
	var pos: Vector2 = entry["pos"]
	pos.y = depth
	entry["pos"] = pos
	game.hook_position = pos
	game.progress = 1.0 - depth


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
