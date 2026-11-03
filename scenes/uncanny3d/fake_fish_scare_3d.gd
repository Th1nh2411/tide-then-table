class_name FakeFishScare3D
extends Node3D
## Jump scare (d), the fake one, once per playthrough (UncannyDirector):
## a calm night on day 2 or 3, while Rin waits on his line. The sound drops,
## then a heavy wet thump on the thúng and a fish lands thrashing at his
## feet... then slips back over the rim. Only a fish: tension let go.
## Nothing is added to the basket. Added by UncannySea3D.

@export var after_seconds := 25.0
@export var flop_seconds := 1.6

var sea: SeaScene3D
var _wait := 0.0
var _started := false


static func attach(host: SeaScene3D) -> FakeFishScare3D:
	if RamNight.is_ram() or not UncannyDirector.fake_scare_due():
		return null
	var scare := FakeFishScare3D.new()
	scare.name = "FakeFishScare"
	scare.sea = host
	host.add_child(scare)
	return scare


func _ready() -> void:
	_wait = after_seconds


func _process(delta: float) -> void:
	if _started or sea.ending:
		return
	var waiting := sea.rod != null and sea.rod.state == Fishing3D.State.WAITING
	if not waiting or sea._at_dock():
		return
	_wait -= delta
	if _wait <= 0.0:
		play()


func play() -> void:
	if _started:
		return
	_started = true
	GameState.set_flag(UncannyDirector.FAKE_FLAG)
	UncannyDirector.mark_scare()
	Sfx.duck(1.4, 0.0)
	await get_tree().create_timer(1.0).timeout
	if not is_instance_valid(sea) or sea.ending:
		return
	var camera := get_viewport().get_camera_3d()
	var forward := -camera.global_basis.z if camera else Vector3.FORWARD
	forward.y = 0.0
	forward = forward.normalized()
	var floor_at := sea.boat_visual.global_position + Vector3(0, FishBasket3D.IN_BOAT.y, 0) + forward * 0.55
	var fish := FishBasket3D.fish_mesh(null, 1.3)
	add_child(fish)
	fish.global_position = floor_at + Vector3.UP * 0.9
	Sfx.play("hull_thump", 0.0)
	Sfx.play("splash", 0.1)
	var tween := create_tween()
	tween.tween_property(fish, "global_position", floor_at, 0.12).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void: Sfx.play("fish_thrash", 0.05))
	for i in 5:
		var hop := floor_at + Vector3(randf_range(-0.12, 0.12), 0.12 - i * 0.02, randf_range(-0.12, 0.12))
		tween.tween_property(fish, "global_position", hop, flop_seconds / 10.0)
		tween.parallel().tween_property(fish, "rotation:z", PI * (0.5 if i % 2 == 0 else -0.5), flop_seconds / 10.0)
		tween.tween_property(fish, "global_position", floor_at, flop_seconds / 10.0)
	tween.tween_interval(0.5)
	# Over the rim and gone.
	tween.tween_property(fish, "global_position", floor_at + forward * 1.1 + Vector3.UP * 0.35, 0.25)
	tween.tween_property(fish, "global_position", floor_at + forward * 1.6 + Vector3.DOWN * 0.6, 0.25)
	tween.tween_callback(func() -> void:
		Sfx.play("slap", 0.1)
		sea._say("...Trời. Cá nhảy.", 2.5)
		fish.queue_free())
