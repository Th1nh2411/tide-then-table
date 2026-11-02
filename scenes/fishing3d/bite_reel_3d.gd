class_name BiteReel3D
extends RefCounted
## The bite window and the fight of the first-person rod, on a Fishing3D:
## when the next bite comes (sooner at a shoal, never in the pier water), the
## "!" window, a missed bite, the hook (species + size, ReelLogic), each reel
## step (tension -> rod bend, line colour, bar, strain sound) and its end:
## landed (fish in hand, Dex record) or snapped.


## Seconds to the next bite where the bobber is.
static func next_bite(f: Fishing3D) -> float:
	if f.target.distance_to(f.sea.START) < f.tuning.dock_quiet_radius:
		return INF  # nothing bites in the pier water
	return ReelLogic.bite_delay(f.tuning, f.sea.rng, f.shoal != null)


static func bite(f: Fishing3D) -> void:
	f.state = Fishing3D.State.BITE
	f.wait_left = f.tuning.bite_window
	f.rod.mark.visible = true
	f.rod.shake = 1.0
	Sfx.play("nibble")


## Too late: the bobber pops back up, the fish is gone; wait for another.
static func missed(f: Fishing3D) -> void:
	f.rod.mark.visible = false
	f.state = Fishing3D.State.WAITING
	f.wait_left = next_bite(f)
	Sfx.play("miss")


static func hook(f: Fishing3D) -> bool:
	if f.state != Fishing3D.State.BITE:
		return false
	f.rod.mark.visible = false
	var rolled := FishingSpot3D.roll(f.sea, f.shoal, f.target)
	f.fish = rolled[0]
	f.size = rolled[1]
	if f.fish == null:
		missed(f)
		return false
	f.reel = ReelLogic.new(f.tuning, ReelLogic.strength_of(f.fish, f.size),
		FishingSpot3D.flat_distance(f.sea, f.target), f.sea.rng)
	f.reel.calm = not GameState.has_flag(LoopCalendar.OMEN_FLAG)  # snaps on đêm âm only
	f.state = Fishing3D.State.REELING
	Sfx.play("bite")
	return true


## One step of the fight; holding the button (or hold_override) reels.
static func reel(f: Fishing3D, delta: float) -> void:
	var held := f.hold_override or Input.is_action_pressed("cast")
	var outcome := f.reel.step(delta, held)
	f.rod.tension = f.reel.tension
	f.bar.show_tension(f.reel.tension)
	var boat := f.sea.boat.global_position
	var dir := Vector3(f.target.x - boat.x, 0, f.target.z - boat.z).normalized()
	var p := boat + dir * maxf(f.reel.distance, 0.6)
	p.y = Fishing3D.WATER_Y - (0.08 if f.reel.running else 0.02) + sin(f.clock * 18.0) * 0.025
	f.rod.place_bobber(p)
	if f.reel.running:
		f.rod.shake = maxf(f.rod.shake, 0.45)
	Sfx.hold("strain", f.reel.tension > 0.8)
	f.reel_tick -= delta
	if held and f.reel_tick <= 0.0:
		f.reel_tick = 0.12
		Sfx.play("reel")
	if outcome == ReelLogic.Outcome.LANDED:
		land(f)
	elif outcome == ReelLogic.Outcome.SNAPPED:
		_snap(f)


## The fish is out of the water: into Rin's hand, into the Dex.
static func land(f: Fishing3D) -> void:
	_end_fight(f)
	Sfx.play("splash")
	f.state = Fishing3D.State.HOLDING
	GameState.record_catch(f.fish, 1, f.size)
	if Story.on_fish_caught(f.fish):
		f.sea._say("Con cá này... sao lại phát sáng?", 3.0)
	f.rod.show_fish(f.fish, f.size)
	f.fish_landed.emit(f.fish, f.size)


static func _snap(f: Fishing3D) -> void:
	_end_fight(f)
	Sfx.play("snap")
	f.state = Fishing3D.State.IDLE
	f.fish = null
	f.sea._say("Đứt dây rồi...", 2.0)
	f.fish_lost.emit(true)


static func _end_fight(f: Fishing3D) -> void:
	Sfx.hold("strain", false)
	f.rod.reel_in()
	f.bar.show_tension(-1.0)
	f.sea.fishing = false
