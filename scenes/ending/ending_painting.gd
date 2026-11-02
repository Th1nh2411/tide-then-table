class_name EndingPainting
extends TextureRect
## The painting behind đêm rằm's ending card (EndingScene): ending_true for
## the true ending, ending_drowned for the drowned one. Fades in slowly from
## black; the ending's lines sit over its lower third in outlined writing;
## `dim()` darkens it for the run card.

const ART := {"true": "ending_true", "drowned": "ending_drowned"}

@export var fade_seconds := 3.5
@export var dim_to := 0.32


## Adds the painting for ending `id` at the back of `parent`; null if none.
static func add(parent: Control, id: String) -> EndingPainting:
	var path := HorrorMaterials.DIR + str(ART.get(id, "")) + ".png"
	if not ART.has(id) or not ResourceLoader.exists(path):
		return null
	var painting := EndingPainting.new()
	painting.texture = load(path) as Texture2D
	painting.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	painting.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	painting.set_anchors_preset(Control.PRESET_FULL_RECT)
	painting.mouse_filter = Control.MOUSE_FILTER_IGNORE
	painting.modulate = Color.BLACK
	parent.add_child(painting)
	parent.move_child(painting, 1)  # right above the plain background
	return painting


func fade_in() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, fade_seconds).set_trans(Tween.TRANS_SINE)
	await tween.finished


func dim(seconds: float = 1.2) -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(dim_to, dim_to, dim_to), seconds)
	await tween.finished


## Pale writing with a dark outline, readable over the painting.
static func outline(label: Label, ink: Color, size: int = 0) -> void:
	label.add_theme_color_override("font_color", ink)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.04, 0.95))
	label.add_theme_constant_override("outline_size", 5)
	if size > 0:
		label.add_theme_font_size_override("font_size", size)
