class_name FishFightBoat
extends RefCounted
## Rin's boat on the fishing screen, side view, one per BoatData id (the
## boat upgrade). Spec coordinates are in boat units relative to the
## waterline point under the boat; the screen shows them x`scale` (2), never
## rotated, so pixels stay square. `deck` is where Rin's feet are.
## Art "fishing/boat_side_<id>" fills `size` x scale on screen (draw it at
## that size, 1 art pixel = 1 screen pixel, deck at y = 6 x scale); the
## lamp pole and lamp are drawn by code.

const INK := Color("090a14")
## size: art size; lamp: lamp centre; rin_x: Rin's feet; deck: deck height.
const SPECS := {
	"thuyen_thung": {"size": Vector2(40, 20), "lamp": Vector2(12, -24), "rin_x": -6.0, "deck": -6.0},
	"ghe_cheo": {"size": Vector2(72, 24), "lamp": Vector2(21, -31), "rin_x": -6.0, "deck": -8.0},
	"ghe_may": {"size": Vector2(96, 28), "lamp": Vector2(30, -36), "rin_x": -14.0, "deck": -9.0},
}


static func spec(id: String) -> Dictionary:
	return SPECS.get(id, SPECS["thuyen_thung"])


## Hull (art or placeholder) at `origin` (screen px), then the lamp pole and lamp.
static func draw(canvas: CanvasItem, id: String, origin: Vector2, scale: float) -> void:
	var s := spec(id)
	var size: Vector2 = s["size"]
	var deck: float = s["deck"]
	var rect := Rect2(origin + Vector2(-size.x * 0.5, deck - 6.0) * scale, size * scale)
	if not Art.draw(canvas, "fishing/boat_side_" + id, rect):
		canvas.draw_set_transform(origin, 0.0, Vector2.ONE * scale)
		match id:
			"ghe_cheo":
				_ghe_cheo(canvas, deck)
			"ghe_may":
				_ghe_may(canvas, deck)
			_:
				_thuyen_thung(canvas, deck)
	canvas.draw_set_transform(origin, 0.0, Vector2.ONE * scale)
	var lamp: Vector2 = s["lamp"]
	canvas.draw_rect(Rect2(lamp.x - 1.0, lamp.y + 1.0, 2.0, deck - lamp.y - 1.0), Color("4d2b32"))
	canvas.draw_circle(lamp, 3.0, Color("f2d98a"))
	canvas.draw_circle(lamp, 7.0, Color(0.95, 0.85, 0.54, 0.18))
	canvas.draw_set_transform(Vector2.ZERO)


## Round bamboo basket boat.
static func _thuyen_thung(canvas: CanvasItem, deck: float) -> void:
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in 13:
		var a := PI * i / 12.0
		outer.append(Vector2(cos(a) * -21.0, deck - 2.0 + sin(a) * 15.0))
		inner.append(Vector2(cos(a) * -19.0, deck - 1.0 + sin(a) * 13.0))
	canvas.draw_colored_polygon(outer, INK)
	canvas.draw_colored_polygon(inner, Color("ad7757"))
	for k in 3:  # woven bands
		var y := deck + 1.0 + k * 4.0
		var half := sqrt(maxf(0.0, 1.0 - pow((y - deck + 1.0) / 13.0, 2.0))) * 18.0
		canvas.draw_rect(Rect2(-half, y, half * 2.0, 1.0), Color("7a4841"))
	canvas.draw_rect(Rect2(-20, deck - 3.0, 40, 2), Color("d7b594"))


## Wooden rowing boat with an oar on the side.
static func _ghe_cheo(canvas: CanvasItem, deck: float) -> void:
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-37, deck - 5), Vector2(-31, deck), Vector2(29, deck),
		Vector2(37, deck - 5), Vector2(27, deck + 17), Vector2(-27, deck + 17)]), INK)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-34, deck - 3), Vector2(-30, deck + 1), Vector2(28, deck + 1),
		Vector2(34, deck - 3), Vector2(25, deck + 15), Vector2(-25, deck + 15)]), Color("884b2b"))
	canvas.draw_rect(Rect2(-30, deck + 4, 58, 2), Color("ad7757"))
	canvas.draw_line(Vector2(-24, deck - 4), Vector2(-34, deck + 14), Color("d7b594"), 2.0)


## Motor boat: long blue hull, small cabin, engine at the stern.
static func _ghe_may(canvas: CanvasItem, deck: float) -> void:
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-49, deck - 4), Vector2(-45, deck), Vector2(40, deck),
		Vector2(49, deck - 8), Vector2(37, deck + 21), Vector2(-41, deck + 21)]), INK)
	canvas.draw_colored_polygon(PackedVector2Array([Vector2(-46, deck - 2), Vector2(-43, deck + 1), Vector2(39, deck + 1),
		Vector2(46, deck - 6), Vector2(35, deck + 19), Vector2(-39, deck + 19)]), Color("3c5e8b"))
	canvas.draw_rect(Rect2(-42, deck + 6, 82, 2), Color("cf573c"))
	canvas.draw_rect(Rect2(6, deck - 13, 19, 14), INK)
	canvas.draw_rect(Rect2(7, deck - 12, 17, 12), Color("ebede9"))
	canvas.draw_rect(Rect2(10, deck - 10, 5, 4), Color("e8c170"))
	canvas.draw_rect(Rect2(-49, deck - 8, 7, 9), INK)
	canvas.draw_rect(Rect2(-48, deck - 7, 5, 7), Color("394a50"))
