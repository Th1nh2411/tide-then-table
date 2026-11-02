class_name OmenOffering3D
extends Node3D
## Cô Năm's mâm cúng cô hồn in front of her shop (a custom: shown on some
## calm nights, OmenPicker.state): a small table with fruit, bowls of cháo
## trắng, a plate of muối gạo, sweets, burning incense and two candles: eerie
## but right. On the "mam_cung" night it has been eaten: fruit gone or on the ground, bowls
## tipped over, wrappers scattered, incense broken, candles out, and wet
## footprints leading off towards the road.

const OMEN_ID := "mam_cung"
const TOP := 0.52
const FRUIT := ["e08a2c", "d9c24a", "9fc04a", "e08a2c", "c94a3a"]

var eaten := false


func _ready() -> void:
	eaten = OmenPicker.state(OMEN_ID) == "omen"
	ConceptModel3D.spawn(self, "offering_tray_eaten" if eaten else "offering_tray_normal", Vector3.ZERO, TOP + 0.35)
	if eaten:
		# Wet footprints from under the table out to the road.
		for i: int in range(6):
			var print_ := OmenProps3D.box(self, Vector3(0.12 * (i % 2) - 0.06, 0.006, 0.55 + i * 0.4), Vector3(0.1, 0.004, 0.22), "1a2228")
			print_.rotation.y = 0.1 * (i % 2)
	else:
		# Candles and incense still burning.
		OmenProps3D.light(self, Vector3(0, TOP + 0.4, 0.1), "ffb347", 0.8, 2.2)
