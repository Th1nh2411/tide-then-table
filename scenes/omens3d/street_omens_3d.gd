class_name StreetOmens3D
extends Node3D
## The street's omen props (OmenPicker.state):
## - "vang_ma" (a custom, some nights): OmenJossFire3D by the curb. The red
##   ribbons on the street trees always show the sea wind (towards home).
## - "tien_le": dry leaves lie scattered at the dock end; on its night a trail
##   of small banknotes leads to the RA BẾN sign.
## - "goi_ten": after the shift, walking towards an end, a neighbour calls
##   someone in for dinner; on its night a voice from the dock calls Rin.

const WIND_X := OmenJossFire3D.WIND_X
const FIRE_POSITION := Vector3(9.0, 0, 7.55)
const CALL_X := 13.0  # Rin is "walking to an end" past this |x|
## Where the voices come from (Sfx.play_at): the omen's from beyond the
## street's end towards the dock, the neighbour's from a house up the far end.
const DOCK_VOICE := Vector3(30.0, 1.6, 8.0)
const HOUSE_VOICE := Vector3(-26.0, 2.0, -6.0)
## Near silence first, then the voice (s into the duck).
const CALL_DUCK := 1.8
const CALL_AFTER := 1.0

var host: RestaurantScene3D
var _ribbons: Array[MeshInstance3D] = []
var _called := false
var _text: OnScreenText
var _time := 0.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	if OmenPicker.state(OmenJossFire3D.OMEN_ID) != "":
		var fire := OmenJossFire3D.new()
		fire.name = "JossFire"
		fire.position = FIRE_POSITION
		add_child(fire)
	for x: float in [-17.0, 17.0]:
		for i: int in range(2):
			var ribbon := OmenProps3D.box(self, Vector3(x + WIND_X * 0.3, 2.3 + i * 0.25, RestaurantLayout3D.CURB_PROP_Z),
				Vector3(0.6, 0.06, 0.01), "c8323a")
			_ribbons.append(ribbon)
	_build_ground(rng, OmenPicker.is_tonight("tien_le"))
	_text = OnScreenText.new()
	add_child(_text)


## Leaves scattered at the dock end, or a trail of small notes to its sign.
func _build_ground(rng: RandomNumberGenerator, notes: bool) -> void:
	for i: int in range(9):
		var at: Vector3
		var piece: MeshInstance3D
		if notes:
			at = Vector3(10.5 + i * 0.95, 0.008, 6.6 + sin(i * 0.9) * 0.35)
			piece = OmenProps3D.glow_box(self, at, Vector3(0.2, 0.004, 0.1), "9cc79a" if i % 2 else "d9a0b4", 0.4)
		else:
			at = Vector3(rng.randf_range(10.5, 18.5), 0.008, rng.randf_range(5.4, 7.8))
			piece = OmenProps3D.box(self, at, Vector3(0.13, 0.004, 0.08), "6b4a2a" if i % 2 else "8a6a3a")
		piece.rotation.y = rng.randf() * TAU


func _process(delta: float) -> void:
	_time += delta
	for i: int in range(_ribbons.size()):
		_ribbons[i].rotation.x = sin(_time * 7.0 + i) * 0.5
	_maybe_call()


## Once per visit, after the shift, on the way to an end of the street.
func _maybe_call() -> void:
	if _called or host == null or not host.shift_over or host.player == null:
		return
	if absf(host.player.global_position.x) < CALL_X:
		return
	_called = true
	var omen := OmenPicker.tonight()
	if omen and omen.id == "goi_ten":
		Sfx.duck(CALL_DUCK)
		create_tween().tween_callback(func() -> void:
			Sfx.play_at("call", DOCK_VOICE, self, 0.92, 10.0)
			_text.say(omen.text, 4.0)).set_delay(CALL_AFTER)
	else:
		var calm := OmenPicker.CATALOG.find("goi_ten")
		if calm:
			Sfx.play_at("call", HOUSE_VOICE, self, 1.3, 10.0)
			_text.say(calm.calm_text, 4.0)
