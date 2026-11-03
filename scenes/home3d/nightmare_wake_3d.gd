class_name NightmareWake3D
extends CanvasLayer
## Waking from a bad night (horror build): whenever the loop resets, Rin jolts
## awake in bed — black screen and a pounding heart, a sharp gasp, his eyes
## open on the ceiling, he sits up shaking, then a line. With `knocks` (the
## drowned came to the door) three slow knocks sound in the black first.
## Drives the village scene's
## `eye_offset` / `held_pitch` (FirstPersonView3D reads them) and `waking`.

## Eye lying on the bed, relative to standing at BedroomBuilder3D.START.
const LYING := Vector3(-0.95, -0.85, -0.15)
const LYING_PITCH := 1.25  # looking up at the ceiling

## Gasp -> eyes open -> sitting up -> control back (s); with dark_seconds or
## knock_dark_seconds this is the whole wake (total_seconds()).
const OPEN_SECONDS := 0.12
const BEFORE_SIT := 0.35
const AFTER_SIT := 0.6
## Wrong-night face (jump scare a): when it shows in the black, for how long.
const FACE_AT := 0.9
const FACE_SECONDS := 0.3

@export var dark_seconds := 1.4
@export var sit_up_seconds := 0.75
## Longer black when someone knocks: near silence, the knocks at the door,
## then a silence. The whole wake stays under 5 s.
@export var knock_dark_seconds := 2.7
@export var knock_at := 0.8

var room: VillageScene3D
var line := ""
var knocks := false
## WrongNightScare3D variant to show in the black first, -1 = none.
var face := -1
var _black := ColorRect.new()
var _shake := 0.0


static func play(owner: VillageScene3D, after: String, knock: bool = false, face_variant: int = -1) -> NightmareWake3D:
	var wake := NightmareWake3D.new()
	wake.face = face_variant
	wake.room = owner
	wake.line = after
	wake.knocks = knock
	owner.add_child(wake)
	return wake


func _ready() -> void:
	layer = 30
	_black.color = Color.BLACK
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_black)
	room.waking = true
	room.eye_offset = LYING
	room.held_pitch = LYING_PITCH
	Sfx.hold("heartbeat", true)
	var tween := create_tween()
	if face >= 0:
		_face_in_the_dark(tween)
	if knocks:
		Sfx.duck(knock_at + 0.9)
		tween.tween_interval(knock_at)
		tween.tween_callback(func() -> void: Sfx.play_at("knock3", VillageLayout3D.room_point(BedroomBuilder3D.DOOR) + Vector3(0, 1.1, 0), room, 1.0, 3.0))
		tween.tween_interval(knock_dark_seconds - knock_at)
	else:
		tween.tween_interval(dark_seconds)
	tween.tween_callback(func() -> void: Sfx.play("gasp", 0.0))
	tween.tween_property(_black, "color:a", 0.0, OPEN_SECONDS)
	tween.tween_interval(BEFORE_SIT)
	tween.tween_callback(func() -> void: _shake = 1.0)
	tween.tween_method(_sit_up, 0.0, 1.0, sit_up_seconds).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(AFTER_SIT)
	tween.tween_callback(_done)


## Jump scare (a) after docking on an omen night: in the black, a face over
## the bed for a moment (WrongNightScare3D), then black again.
func _face_in_the_dark(tween: Tween) -> void:
	var scare: Array[WrongNightScare3D] = []
	Sfx.duck(1.4, 0.0)
	tween.tween_interval(FACE_AT)
	tween.tween_callback(func() -> void:
		var shown := WrongNightScare3D.show_face(room, face)
		if shown:
			scare.append(shown)
			_black.color.a = 0.0)
	tween.tween_interval(FACE_SECONDS)
	tween.tween_callback(func() -> void:
		_black.color.a = 1.0
		for shown in scare:
			shown.queue_free())


## Seconds from the black screen to Rin moving again.
func total_seconds() -> float:
	var face_time := FACE_AT + FACE_SECONDS if face >= 0 else 0.0
	return face_time + (knock_dark_seconds if knocks else dark_seconds) + OPEN_SECONDS + BEFORE_SIT + sit_up_seconds + AFTER_SIT


func _process(delta: float) -> void:
	if _shake <= 0.0:
		return
	_shake = maxf(_shake - delta * 0.7, 0.0)
	var jitter := Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * 0.012 * _shake
	room.eye_offset += jitter


func _sit_up(t: float) -> void:
	room.eye_offset = LYING.lerp(Vector3.ZERO, t)
	room.held_pitch = lerpf(LYING_PITCH, -0.12, t)


func _done() -> void:
	Sfx.hold("heartbeat", false)
	room.eye_offset = Vector3.ZERO
	room.held_pitch = NAN
	room.waking = false
	if line != "":
		room.text.say(line, 4.5)
	queue_free()
