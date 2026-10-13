class_name StrandedBoat
extends PointOfInterest
## Night event: a fisherman whose engine died. Accept to tow him: his boat
## follows yours on a rope and slows you down; dock to get paid (NightEvents
## pays at the end of the trip).

@export var boat: Boat
@export var reward: int = 80
@export var owner_name: String = "Chú Sáu"
## Top speed multiplier while towing.
@export var tow_speed_scale: float = 0.65
@export var rope_length: float = 26.0

var towing: bool = false


func _interact() -> void:
	var choice := await dialog.ask(title,
		"%s: \"Máy chết rồi con ơi. Kéo giùm chú về bến, chú gửi %dk.\"" % [owner_name, reward],
		PackedStringArray(["Kéo về bến (thuyền chạy chậm lại)", "Thôi, con đang bận"]))
	if choice != 0:
		return
	towing = true
	_busy = true
	monitoring = false
	boat.tow_multiplier = tow_speed_scale
	hud.flash_message("Kéo ghe %s về bến là có %dk." % [owner_name, reward], 2.5)


func _process(delta: float) -> void:
	super(delta)
	if towing and is_instance_valid(boat):
		_busy = true  # the base class clears it after a visit; no more prompts
		var behind := boat.global_position - Vector2.RIGHT.rotated(boat.rotation) * rope_length
		global_position = global_position.lerp(behind, minf(delta * 6.0, 1.0))


func _draw() -> void:
	if towing and is_instance_valid(boat):
		draw_line(Vector2.ZERO, to_local(boat.global_position), Color(0.8, 0.7, 0.5), 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(10, 0), Vector2(4, -5), Vector2(-9, -5),
		Vector2(-9, 5), Vector2(4, 5)]), Color(0.45, 0.45, 0.42))
	# Distress lantern blinking.
	if towing or fmod(_time, 1.0) < 0.6:
		draw_circle(Vector2(-4, 0), 2.0, Color(1.0, 0.4, 0.3))
	if not towing:
		super()
