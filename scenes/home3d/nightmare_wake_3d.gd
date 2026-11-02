class_name NightmareWake3D
extends CanvasLayer
## Waking from a bad night (horror build): whenever the loop resets, Rin jolts
## awake in bed — black screen and a pounding heart, a sharp gasp, his eyes
## open on the ceiling, he sits up shaking, then a line. With `knocks` (the
## drowned came to the door) three slow knocks sound in the black first.
## Drives the bedroom's
## `eye_offset` / `held_pitch` (FirstPersonView3D reads them) and `waking`.

## Eye lying on the bed, relative to standing at BedroomBuilder3D.START.
const LYING := Vector3(-0.95, -0.85, -0.15)
const LYING_PITCH := 1.25  # looking up at the ceiling

@export var dark_seconds := 1.4
@export var sit_up_seconds := 0.75
## Longer black when someone knocks: the knocks, then a silence.
@export var knock_dark_seconds := 3.2
@export var knock_at := 0.5

var room: BedroomScene3D
var line := ""
var knocks := false
var _black := ColorRect.new()
var _shake := 0.0


static func play(owner: BedroomScene3D, after: String, knock: bool = false) -> NightmareWake3D:
	var wake := NightmareWake3D.new()
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
	if knocks:
		tween.tween_interval(knock_at)
		tween.tween_callback(func() -> void: Sfx.play("knock3", 0.0))
		tween.tween_interval(knock_dark_seconds - knock_at)
	else:
		tween.tween_interval(dark_seconds)
	tween.tween_callback(func() -> void: Sfx.play("gasp", 0.0))
	tween.tween_property(_black, "color:a", 0.0, 0.12)
	tween.tween_interval(0.35)
	tween.tween_callback(func() -> void: _shake = 1.0)
	tween.tween_method(_sit_up, 0.0, 1.0, sit_up_seconds).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.6)
	tween.tween_callback(_done)


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
