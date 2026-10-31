class_name FishFightFeel
extends RefCounted
## How the rod fight feels: reel clicks while reeling (faster as the fish
## comes up), a whining line when the tension is high, a snap when it
## breaks, wheel ticks while the all-in wheel spins, a short freeze + ring
## when a fish bites, and screen shakes (the game Control is nudged a few
## pixels). Sounds are Sfx recipes ("reel", "strain", "snap", "tick").

## Seconds between reel clicks: slow at the start, fast near the surface.
const REEL_SLOW := 0.12
const REEL_FAST := 0.055
const STRAIN_TENSION := 0.75
const BITE_FREEZE := 0.07
const WHEEL_SLICES := 16

var game: FishFightGame
## Seconds left of the bite freeze (the game skips its update meanwhile).
var hitstop: float = 0.0
var _reel_clock: float = 0.0
var _wheel_slice: int = 0
var _shake_left: float = 0.0
var _shake_seconds: float = 0.0
var _shake_power: float = 0.0


func _init(owner: FishFightGame) -> void:
	game = owner
	game.tugged.connect(func() -> void: shake(2.0, 0.18))
	game.fish_hooked.connect(_on_hooked)
	game.yanked.connect(_on_yanked)
	game.boat_bumped.connect(func() -> void:
		Sfx.play("bump")
		shake(3.0, 0.25))


func tick(delta: float) -> void:
	var fighting := game.hooked_index >= 0 and not game._done
	if fighting and game.reeling:
		_reel_clock -= delta
		if _reel_clock <= 0.0:
			Sfx.play("reel", 0.08)
			_reel_clock = lerpf(REEL_SLOW, REEL_FAST, game.progress)
	Sfx.hold("strain", fighting and game.tension > STRAIN_TENSION)
	if game.yank_spinning:
		var slice := floori(game._pointer_angle / (TAU / WHEEL_SLICES))
		if slice != _wheel_slice:
			Sfx.play("tick", 0.02)
			_wheel_slice = slice
	if _shake_left > 0.0:
		_shake_left = maxf(_shake_left - delta, 0.0)
		var power := _shake_power * _shake_left / maxf(_shake_seconds, 0.001)
		game.position = Vector2(randf_range(-power, power), randf_range(-power, power)).round()
	elif game.position != Vector2.ZERO:
		game.position = Vector2.ZERO


## Pixels of jitter fading out over `seconds`; a stronger shake wins.
func shake(power: float, seconds: float) -> void:
	if _shake_left > 0.0 and power < _shake_power * _shake_left / maxf(_shake_seconds, 0.001):
		return
	_shake_power = power
	_shake_seconds = seconds
	_shake_left = seconds


func on_finish(success: bool) -> void:
	Sfx.hold("strain", false)
	if not success and game.tension >= 1.0:
		Sfx.play("snap")
		shake(4.0, 0.3)


func stop() -> void:
	Sfx.hold("strain", false)
	game.position = Vector2.ZERO


func _on_hooked(_size_scale: float) -> void:
	hitstop = BITE_FREEZE
	shake(3.0, 0.22)
	game._view.ring(game._view.hook_screen())


func _on_yanked(result: FishFightGame.YankResult) -> void:
	match result:
		FishFightGame.YankResult.YELLOW:
			Sfx.play("pluck")
			shake(2.5, 0.2)
		FishFightGame.YankResult.RED:
			Sfx.play("bump")
			shake(5.0, 0.35)
