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
	OmenProps3D.box(self, Vector3(0, TOP - 0.03, 0), Vector3(0.95, 0.06, 0.6), "7a4841")
	for x: float in [-0.42, 0.42]:
		for z: float in [-0.25, 0.25]:
			OmenProps3D.box(self, Vector3(x, (TOP - 0.06) * 0.5, z), Vector3(0.05, TOP - 0.06, 0.05), "4a3a2e")
	# Fruit plate, back left.
	OmenProps3D.box(self, Vector3(-0.25, TOP + 0.01, -0.1), Vector3(0.34, 0.02, 0.3), "e8d9b7")
	# Gold paper stack, back right.
	OmenProps3D.box(self, Vector3(0.3, TOP + 0.03, -0.15), Vector3(0.2, 0.06, 0.12), "d8b24a")
	OmenProps3D.box(self, Vector3(0, TOP + 0.04, -0.2), Vector3(0.12, 0.08, 0.12), "6b5a4a")  # incense pot
	if eaten:
		_build_eaten()
	else:
		_build_calm()


func _build_calm() -> void:
	var at := Vector3(-0.25, TOP + 0.08, -0.1)
	for i: int in range(4):
		OmenProps3D.sphere(self, at + Vector3((i % 2) * 0.12 - 0.06, 0, (i / 2) * 0.12 - 0.06), 0.06, FRUIT[i])
	OmenProps3D.sphere(self, at + Vector3(0, 0.1, 0), 0.06, FRUIT[4])
	for i: int in range(3):
		OmenProps3D.box(self, Vector3(-0.2 + i * 0.2, TOP + 0.035, 0.17), Vector3(0.12, 0.07, 0.12), "efe9dc")
	# Muối gạo: salt and rice, two small heaps on a saucer.
	OmenProps3D.box(self, Vector3(0, TOP + 0.005, -0.02), Vector3(0.16, 0.01, 0.1), "e8d9b7")
	OmenProps3D.box(self, Vector3(-0.04, TOP + 0.025, -0.02), Vector3(0.05, 0.03, 0.05), "f4f4f0")
	OmenProps3D.box(self, Vector3(0.04, TOP + 0.025, -0.02), Vector3(0.05, 0.03, 0.05), "e6dcc0")
	for i: int in range(4):
		OmenProps3D.box(self, Vector3(0.18 + (i % 2) * 0.09, TOP + 0.02 + (i / 2) * 0.04, 0.02), Vector3(0.08, 0.04, 0.08), ["d24a5a", "4a8ad2", "e0c040", "6ac06a"][i])
	for i: int in range(3):
		OmenProps3D.box(self, Vector3(-0.03 + i * 0.03, TOP + 0.2, -0.2), Vector3(0.01, 0.24, 0.01), "8a5a3a")
		OmenProps3D.glow_box(self, Vector3(-0.03 + i * 0.03, TOP + 0.33, -0.2), Vector3(0.018, 0.02, 0.018), "ff3a1a", 4.0)
	for x: float in [-0.42, 0.42]:
		OmenProps3D.box(self, Vector3(x, TOP + 0.08, 0.22), Vector3(0.05, 0.16, 0.05), "c8323a")
		OmenProps3D.glow_box(self, Vector3(x, TOP + 0.19, 0.22), Vector3(0.025, 0.05, 0.025), "ffb347", 4.0)
	OmenProps3D.light(self, Vector3(0, TOP + 0.4, 0.1), "ffb347", 0.8, 2.2)


func _build_eaten() -> void:
	OmenProps3D.sphere(self, Vector3(-0.3, TOP + 0.08, -0.05), 0.06, FRUIT[1])
	OmenProps3D.sphere(self, Vector3(-0.35, 0.06, 0.55), 0.06, FRUIT[0])
	OmenProps3D.sphere(self, Vector3(0.5, 0.06, 0.75), 0.05, FRUIT[3])
	var tipped := OmenProps3D.box(self, Vector3(-0.2, TOP + 0.06, 0.17), Vector3(0.12, 0.07, 0.12), "efe9dc")
	tipped.rotation.z = PI * 0.5
	OmenProps3D.box(self, Vector3(0.2, TOP + 0.035, 0.17), Vector3(0.12, 0.07, 0.12), "efe9dc")
	# Salt and rice swept off the table.
	for i: int in range(5):
		OmenProps3D.box(self, Vector3(0.35 + i * 0.07, 0.006, 0.3 + (i % 2) * 0.08), Vector3(0.05, 0.004, 0.04), "f4f4f0")
	var fallen := OmenProps3D.box(self, Vector3(0.15, 0.06, 0.45), Vector3(0.12, 0.07, 0.12), "efe9dc")
	fallen.rotation = Vector3(PI * 0.5, 0.4, 0)
	for i: int in range(6):
		var wrapper := OmenProps3D.box(self, Vector3(-0.6 + i * 0.25, 0.01, 0.4 + (i % 3) * 0.2), Vector3(0.08, 0.005, 0.06), ["d24a5a", "4a8ad2", "e0c040"][i % 3])
		wrapper.rotation.y = i * 1.3
	for i: int in range(3):
		var stick := OmenProps3D.box(self, Vector3(-0.03 + i * 0.03, TOP + 0.12, -0.2), Vector3(0.01, 0.08, 0.01), "8a5a3a")
		stick.rotation.z = (i - 1) * 0.6
	for x: float in [-0.42, 0.42]:
		OmenProps3D.box(self, Vector3(x, TOP + 0.05, 0.22), Vector3(0.05, 0.1, 0.05), "c8323a")
	# Wet footprints from under the table out to the road.
	for i: int in range(6):
		var print_ := OmenProps3D.box(self, Vector3(0.12 * (i % 2) - 0.06, 0.006, 0.55 + i * 0.4), Vector3(0.1, 0.004, 0.22), "1a2228")
		print_.rotation.y = 0.1 * (i % 2)
