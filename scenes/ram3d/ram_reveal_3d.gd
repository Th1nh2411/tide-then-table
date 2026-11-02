class_name RamReveal3D
extends RefCounted
## True ending at sea (refused the tea, PLAN §10 H7): the ghost-lights end at
## the lobster raft. Under its green lamp, anh Út drags a body wrapped in net
## to the far edge and drops it into the fog; Rin's lamp flickers on him, he
## turns and sees Rin. Rin rows back into the dark. -> RamEpilogue3D (true).
## Sound: near silence as the raft comes into view; when he looks up, the one
## moment of full silence in the game (bed and ambience off, SILENCE s).

const RAFT_TOP := 0.62
const SILENCE := 1.5


static func play(ram: RamSea3D) -> void:
	var sea := ram.sea
	Sfx.duck(1.6)
	sea.ending = true
	sea.boat.velocity = Vector3.ZERO
	sea.yaw_velocity = 0.0
	var dir := sea.RAFT_POS - sea.boat.position
	dir.y = 0.0
	dir = dir.normalized()
	var turn := sea.create_tween()
	turn.tween_property(sea.boat, "rotation:y", atan2(-dir.x, -dir.z), RamNight.secs(1.0))
	# Anh Út walks backwards to the far edge, pulling the body after him.
	var start := sea.RAFT_POS + dir * 0.2 + Vector3(0, RAFT_TOP, 0)
	var ut := PersonRig3D.build(ram, "guest_rich")
	ut.position = start
	ut.rotation.y = atan2(-dir.x, -dir.z)  # facing the boat side, his back to the fog
	var body := OmenProps3D.box(ram, start - dir * 1.0 + Vector3(0, 0.18, 0), Vector3(0.45, 0.32, 1.6), "2e3128")
	body.rotation.y = atan2(dir.x, dir.z)
	var lamp := OmenProps3D.glow_box(ram, sea.RAFT_POS + Vector3(0.8, 1.6, 0), Vector3(0.16, 0.22, 0.16), "39ff8a", 4.0)
	var lamp_light := OmenProps3D.light(ram, sea.RAFT_POS + Vector3(0.8, 1.8, 0), "39ff8a", 2.5, 10.0)
	var flash := RamFx3D.veil(ram, "e8f4f0", 0.0, 46)
	var black := RamFx3D.veil(ram, "000000", 0.0, 47)
	ram.text.say(RamFx3D.LINES.whispers_trail.back() if not RamFx3D.LINES.whispers_trail.is_empty() else "", 2.0)
	await turn.finished
	Sfx.play("drag")
	ut.set_walking(0.35, 0.0)
	var drag := sea.create_tween().set_parallel()
	drag.tween_property(ut, "position", start + dir * 1.8, RamNight.secs(4.5))
	drag.tween_property(body, "position", start + dir * 0.9 + Vector3(0, 0.18, 0), RamNight.secs(4.5))
	await _flash(ram, flash, 1.0)
	await _flash(ram, flash, 1.6)
	if drag.is_running():
		await drag.finished
	ut.set_walking(0.0, 0.0)
	# Over the edge, into the water and the fog.
	var drop := sea.create_tween()
	drop.tween_property(body, "position", start + dir * 2.9 + Vector3(0, -1.6, 0), RamNight.secs(0.8)).set_ease(Tween.EASE_IN)
	await drop.finished
	Sfx.play("splash")
	body.visible = false
	await RamFx3D.wait(ram, 0.4)
	# He looks up, straight at Rin's lamp: nothing at all to hear.
	Sfx.duck(SILENCE + 0.3, 0.0)
	await RamFx3D.wait(ram, SILENCE)
	Sfx.hold("heartbeat", true)
	await _flash(ram, flash, 0.2)
	await RamFx3D.say_lines(ram.text, RamFx3D.LINES.ut_seen, 2.4)
	lamp.visible = false
	lamp_light.visible = false
	Sfx.play("static")
	# Rin rows away into the dark.
	var away := sea.START - sea.boat.position
	var back := sea.create_tween().set_parallel()
	back.tween_property(sea.boat, "rotation:y", atan2(-away.x, -away.z), RamNight.secs(1.2))
	back.tween_property(sea.boat, "position", sea.boat.position + away.normalized() * 7.0, RamNight.secs(3.0))
	back.tween_property(black, "color:a", 1.0, RamNight.secs(2.6)).set_delay(RamNight.secs(0.6))
	await back.finished
	Sfx.hold("heartbeat", false)
	RamNight.finish(RamNight.Ending.TRUE)
	SceneRouter.go_to(RamEpilogue3D.SCENE)


## The lamp catches him: a pale flash with radio-like static.
static func _flash(ram: RamSea3D, flash: ColorRect, delay: float) -> void:
	await RamFx3D.wait(ram, delay)
	Sfx.play("static")
	for alpha: float in [0.45, 0.0, 0.3, 0.0]:
		flash.color.a = alpha
		await RamFx3D.wait(ram, 0.07)
