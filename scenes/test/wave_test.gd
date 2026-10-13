extends Node
## Standalone test for Nhịp Sóng (run with F6): who has it, charges from
## aberrant catches, harder fights, the slow-down itself (time scale, Rin
## keeps his speed, charges, ends by itself / when not allowed any more),
## and the cutscene's if_flag branch.

var _failures: int = 0
var _allowed: bool = true


func _ready() -> void:
	GameState.reset()
	_check("no power before the omen", not WaveMark.has_power() and WaveMark.max_charges() == 2)
	GameState.caught_species["ca_thu_phat_sang"] = 7
	_check("+1 use per 3 aberrant fish, capped", WaveMark.max_charges() == 4)
	var catalog: FishCatalog = load(WaveMark.FISH_CATALOG_PATH)
	var glowing: FishData = null
	var plain: FishData = null
	for fish in catalog.fish:
		if fish.is_aberrant:
			glowing = fish
		elif plain == null:
			plain = fish
	_check("no extra difficulty without the power", WaveMark.fight_scale(glowing, true) == 1.0)
	GameState.set_flag(WaveMark.FLAG)
	_check("harder: big or aberrant only", WaveMark.fight_scale(glowing, false) < 1.0
		and WaveMark.fight_scale(plain, true) < 1.0 and WaveMark.fight_scale(plain, false) == 1.0)
	var power := WavePower.new()
	power.can_use = func() -> bool: return _allowed
	power.keep_rin_speed = true
	power.seconds = 0.3
	add_child(power)
	_check("starts with the max charges", power.charges == 4)
	_check("use: world slowed, Rin unslowed", power.use() and Engine.time_scale < 1.0 and WavePower.rin_unslowed
		and power.charges == 3)
	_check("can't stack", not power.use() and power.charges == 3)
	await get_tree().create_timer(0.5, true, false, true).timeout
	_check("ends by itself", not WavePower.active and Engine.time_scale == 1.0 and not WavePower.rin_unslowed)
	_allowed = false
	_check("not allowed -> no use", not power.use() and power.charges == 3)
	_allowed = true
	power.use()
	_allowed = false
	await get_tree().process_frame
	await get_tree().process_frame
	_check("stops when no longer allowed", not WavePower.active and Engine.time_scale == 1.0)
	power.queue_free()
	# Cutscene branch
	var commands := CutsceneScript.parse("if_flag wave_mark yes\nnarrate \"no\"\nlabel yes")
	_check("if_flag parses", commands.size() == 3 and commands[0]["cmd"] == "if_flag")
	GameState.reset()
	print("wave_test: %s" % ("ALL PASS" if _failures == 0 else "%d FAIL" % _failures))
	get_tree().quit()


func _check(label: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		_failures += 1
