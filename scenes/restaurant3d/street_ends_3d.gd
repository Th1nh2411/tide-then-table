class_name StreetEnds3D
extends Node3D
## The two ends of the restaurant's street (horror build): the left end goes
## home to sleep, the right end down to the dock. Walking to one shows its
## prompt; E leaves through it (RestaurantShift3D.leave). Not during a shift.

## Rin is at an end once past this |x| (the street walls stand at ±20).
const END_X := 18.3
const SIGN_Z := 6.8

var host: RestaurantScene3D
var _text: OnScreenText


static func build(owner: RestaurantScene3D) -> StreetEnds3D:
	var ends := StreetEnds3D.new()
	ends.name = "StreetEnds"
	ends.host = owner
	owner.add_child(ends)
	return ends


func _ready() -> void:
	_text = OnScreenText.new()
	add_child(_text)
	for side: float in [-1.0, 1.0]:
		var post := RestaurantRoomBuilder3D.box(self, Vector3(side * 19.2, 0.9, SIGN_Z), Vector3(0.08, 1.8, 0.08), "4a3a2e")
		post.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		# The board faces back up the street, towards the shop.
		var board := RestaurantRoomBuilder3D.box(self, Vector3(side * 19.2, 1.75, SIGN_Z), Vector3(0.9, 0.3, 0.05), "c9b896")
		board.rotation.y = -side * PI * 0.5
		var words := "VỀ NHÀ" if side < 0 else "RA BẾN"
		var label := RestaurantRoomBuilder3D.label(self, words, Vector3(side * 19.17, 1.75, SIGN_Z), 30, "2a2230")
		label.rotation.y = -side * PI * 0.5


## -1 at the home end, 1 at the dock end, 0 elsewhere.
func side() -> int:
	var x := host.player.global_position.x
	return -1 if x < -END_X else (1 if x > END_X else 0)


func can_leave() -> bool:
	return not host.shift_running and not host.sailing and not host.modal_open() and not get_tree().paused


func _process(_delta: float) -> void:
	var at := side()
	if at == 0:
		_text.prompt("")
	elif not can_leave():
		_text.prompt("Đang trong ca" if host.shift_running else "")
	else:
		_text.prompt("E  Về nhà ngủ" if at < 0 else "E  Ra bến")


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or key.physical_keycode != KEY_E:
		return
	var at := side()
	if at == 0 or not can_leave():
		return
	get_viewport().set_input_as_handled()
	_text.prompt("")
	if at < 0:
		host._go_home()
	else:
		host._sail()
