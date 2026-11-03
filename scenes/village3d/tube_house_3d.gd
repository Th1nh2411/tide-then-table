class_name TubeHouse3D
extends RefCounted
## One Vietnamese tube house (nhà ống) for the village streets: plaster body,
## ground floor with a rolling shutter or an open shop mouth, a balcony with a
## railing, shuttered windows (some lit at night: `night` batch), and a tin
## gable, a parapet with a water tank or a shed roof. Uses a tube_house_a/b/c
## model when one is delivered (VillageProps3D). Origin: front-centre on the
## ground; the front faces local +Z; `yaw` turns it.

const WALLS := [
	["wall_plaster_old", Color(0.86, 0.82, 0.7)],
	["blue_lime_wall", Color(0.78, 0.84, 0.84)],
	["wall_plaster_old", Color(0.74, 0.8, 0.7)],
	["wall_plaster_old", Color(0.86, 0.74, 0.7)],
	["wall_plaster_old", Color(0.7, 0.7, 0.68)],
]
const FLOOR_H := 3.2


## `style` picks colours / roof / ground floor; `shop` leaves the ground floor open.
## `awning` false: no balcony / awning (the restaurant's own awning runs in front).
static func build(parent: Node3D, day: BoxBatch3D, night: BoxBatch3D, at: Vector3, size: Vector3, yaw: float, style: int, shop: bool = false, awning: bool = true) -> void:
	var model: String = "tube_house_" + ["a", "b", "c"][style % 3]
	if VillageProps3D.kind(model) != "":
		VillageProps3D.place(parent, model, at - Vector3(0, 0, size.z * 0.5).rotated(Vector3.UP, yaw), size, yaw)
		return
	var p := VillageStandins3D.Put.new(day, at, yaw, size)
	var w := size.x
	var h := size.y
	var d := size.z
	var spec: Array = WALLS[style % WALLS.size()]
	var wall := HorrorMaterials.tiled(spec[0], 2.2, spec[1])
	var dark := BoxBatch3D.color("1d1f22")
	var trim := BoxBatch3D.color("8a8478")
	p.box(wall, Vector3(0, h * 0.5, -d * 0.5), Vector3(w - 0.06, h, d))
	# Ground floor: shop mouth (dark inside) or a rolling shutter.
	if shop:
		p.box(dark, Vector3(0, 1.35, 0.01), Vector3(w * 0.82, 2.7, 0.04))
		# A dim lamp-lit back wall inside, and the shutter half down over the top.
		night.box(BoxBatch3D.color("9a6a3a", 0.45), at + Vector3(0, 1.2, 0.03).rotated(Vector3.UP, yaw), Vector3(w * 0.6, 1.9, 0.03), yaw)
		p.box(HorrorMaterials.tiled("roof_tin_rusty", 0.7, Color(0.62, 0.64, 0.66)), Vector3(0, 2.35, 0.05), Vector3(w * 0.82, 0.7, 0.05))
	else:
		p.box(HorrorMaterials.tiled("roof_tin_rusty", 0.7, Color(0.62, 0.64, 0.66)), Vector3(0, 1.35, 0.02), Vector3(w * 0.82, 2.7, 0.05))
		p.box(trim, Vector3(0, 2.75, 0.05), Vector3(w * 0.86, 0.12, 0.14))
	# Floor slab lip, balcony, railing.
	p.box(trim, Vector3(0, FLOOR_H, 0.12), Vector3(w, 0.2, 0.3))
	if not awning:
		pass
	elif style % 2 == 0 and h > FLOOR_H + 2.0:
		p.box(trim, Vector3(0, FLOOR_H + 0.05, 0.55), Vector3(w * 0.9, 0.12, 1.1))
		var iron := BoxBatch3D.color("2a2e30")
		p.box(iron, Vector3(0, FLOOR_H + 1.0, 1.08), Vector3(w * 0.9, 0.05, 0.05))
		for i in 7:
			var x := (float(i) / 6.0 - 0.5) * w * 0.88
			p.box(iron, Vector3(x, FLOOR_H + 0.55, 1.08), Vector3(0.04, 0.9, 0.04))
	else:
		# Tin awning over the ground floor.
		p.box(HorrorMaterials.tiled("roof_tin_rusty", 1.4), Vector3(0, 2.95, 0.7), Vector3(w * 0.95, 0.05, 1.4), 0.0, 0.22)
	# Upper windows: wooden shutters, dark glass; some lit at night.
	var floors := maxi(int((h - 0.6) / FLOOR_H), 1)
	var shutter := HorrorMaterials.tiled("door_wood_old", 0.9, Color(0.55, 0.6, 0.55))
	for f in range(1, floors):
		var y := FLOOR_H * float(f) + 1.5
		var count := 2 if w > 4.5 else 1
		for i in count:
			var x := (float(i) + 0.5) / float(count) * w - w * 0.5 if count > 1 else 0.0
			p.box(dark, Vector3(x, y, 0.01), Vector3(0.9, 1.2, 0.04))
			p.box(shutter, Vector3(x - 0.62, y, 0.03), Vector3(0.32, 1.25, 0.04), 0.4)
			p.box(shutter, Vector3(x + 0.62, y, 0.03), Vector3(0.32, 1.25, 0.04), -0.4)
			if (style + f + i) % 3 != 1:
				night.box(BoxBatch3D.color("e8b46a", 1.2), at + Vector3(x, y, 0.035).rotated(Vector3.UP, yaw), Vector3(0.8, 1.1, 0.02), yaw)
		# A small window on each side wall, towards the back (sides show at corners).
		for side: float in [-1.0, 1.0]:
			p.box(dark, Vector3(side * (w * 0.5 - 0.02), y, -d * 0.65), Vector3(0.06, 0.9, 0.7))
	_roof(p, style, w, h, d)


static func _roof(p: VillageStandins3D.Put, style: int, w: float, h: float, d: float) -> void:
	var tin := HorrorMaterials.tiled("roof_tin_rusty", 1.4)
	match style % 3:
		0:  # gable end to the street
			p.gable(tin, Vector3(0, h, -d * 0.5), Vector3(d + 0.6, 1.4, w + 0.5), PI * 0.5)
		1:  # parapet + a water tank on the flat roof
			p.box(BoxBatch3D.color("8a8478"), Vector3(0, h + 0.35, 0.0), Vector3(w, 0.7, 0.15))
			p.box(BoxBatch3D.color("9aa0a0"), Vector3(w * 0.2, h + 0.6, -1.5), Vector3(1.0, 1.2, 1.0), 0.3)
			p.box(tin, Vector3(-w * 0.2, h + 1.0, -d * 0.6), Vector3(w * 0.5, 0.05, 2.4), 0.0, -0.15)
		_:  # one slope down to the back
			p.box(tin, Vector3(0, h + 0.45, -d * 0.5), Vector3(w + 0.3, 0.05, d + 0.6), 0.0, -0.1)
			p.box(HorrorMaterials.tiled(WALLS[style % WALLS.size()][0], 2.2), Vector3(0, h + 0.45, 0.0), Vector3(w, 0.9, 0.12))
