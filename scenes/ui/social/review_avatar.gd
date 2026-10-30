class_name ReviewAvatar
extends Control
## A post author's pixel portrait in a square frame: final art
## assets/sprites/ui/avatars/<id>.png (24x24) if present, else a tiny
## placeholder face (skin, hair, shirt picked from the id).

const SKINS: Array[Color] = [Color("e7d5b3"), Color("d7b594"), Color("c09473"), Color("ad7757")]
const HAIRS: Array[Color] = [Color("090a14"), Color("4d2b32"), Color("602c2c"), Color("2c4058")]
const SHIRTS: Array[Color] = [Color("4f8fba"), Color("a53030"), Color("468232"), Color("de9e41"), Color("c65197"), Color("577277")]

var avatar_id: String = ""


func _init(id: String = "", px: float = 20.0) -> void:
	avatar_id = id
	custom_minimum_size = Vector2(px, px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size).grow(-1.0)
	draw_rect(Rect2(Vector2(2, 2), size), SocialStyle.INK)  # hard shadow
	draw_rect(Rect2(Vector2.ZERO, size), SocialStyle.INK)
	var art := Art.texture("ui/avatars/" + avatar_id)
	if art:
		draw_texture_rect(art, r, false)
		return
	var seed := absi(hash(avatar_id))
	draw_rect(r, Color("a4dddb"))
	var u := r.size.x / 10.0
	var o := r.position
	var skin: Color = SKINS[seed % SKINS.size()]
	var hair: Color = HAIRS[(seed / 7) % HAIRS.size()]
	var shirt: Color = SHIRTS[(seed / 13) % SHIRTS.size()]
	draw_rect(Rect2(o + Vector2(1, 7) * u, Vector2(8, 3) * u), shirt)
	draw_rect(Rect2(o + Vector2(3, 2) * u, Vector2(4, 5) * u), skin)
	draw_rect(Rect2(o + Vector2(2.5, 1) * u, Vector2(5, 2) * u), hair)
	if seed % 3 == 0:  # long hair
		draw_rect(Rect2(o + Vector2(2.5, 2) * u, Vector2(1, 4) * u), hair)
		draw_rect(Rect2(o + Vector2(6.5, 2) * u, Vector2(1, 4) * u), hair)
	draw_rect(Rect2(o + Vector2(4, 4) * u, Vector2(0.8, 0.8) * u), SocialStyle.INK)
	draw_rect(Rect2(o + Vector2(5.4, 4) * u, Vector2(0.8, 0.8) * u), SocialStyle.INK)
