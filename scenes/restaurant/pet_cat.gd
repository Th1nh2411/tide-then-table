class_name PetCat
extends Control
## The restaurant cat (adopted in the "cat_arrival" cutscene; name in
## story_flags "pet_name"). Sits by the food cart, purrs, and Rin can talk to
## it (child Talker). While it's here customers are a bit more patient
## ("mèo chiêu tài", CustomerManager reads is_present()).

const ADOPTED_FLAG: String = "cat_adopted"
const GONE_FLAG: String = "cat_gone"

@export var sit_position: Vector2 = Vector2(20, 158)
@export var fur: Color = Color(0.95, 0.6, 0.25)

var _time: float = 0.0


static func is_present() -> bool:
	return GameState.has_flag(ADOPTED_FLAG) and not GameState.has_flag(GONE_FLAG)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = is_present()
	var talker := get_node_or_null("Talker") as Talker
	if talker:
		talker.display_name = CutsceneScript.pet_name()
		if not visible:
			talker.remove_from_group("talkers")


func talk_position() -> Vector2:
	return sit_position


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var at := sit_position
	draw_circle(at + Vector2(0, -6), 7.0, fur)  # loaf body
	draw_circle(at + Vector2(-6, -11), 4.0, fur)  # head, facing left
	draw_colored_polygon(PackedVector2Array([at + Vector2(-9, -14), at + Vector2(-9, -18), at + Vector2(-6, -14)]), fur)
	draw_colored_polygon(PackedVector2Array([at + Vector2(-5, -14), at + Vector2(-3, -18), at + Vector2(-2, -13)]), fur)
	draw_line(at + Vector2(6, -4), at + Vector2(10, -8 + sin(_time * 2.0) * 2.0), fur, 2.0)  # tail
	# Eyes half closed; a faint glow now and then (it isn't quite a cat...).
	var glow := 0.5 + 0.5 * sin(_time * 0.7)
	draw_line(at + Vector2(-8, -12), at + Vector2(-7, -12), Color(0.2, 0.9, 0.6, 0.4 + 0.6 * glow), 1.0)
	var talker := get_node_or_null("Talker") as Talker
	if talker and talker.has_news():
		draw_string(ThemeDB.fallback_font, at + Vector2(-8, -22), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
			Color(1, 0.85, 0.3))
