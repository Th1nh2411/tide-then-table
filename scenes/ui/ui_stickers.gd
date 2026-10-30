class_name UiStickers
extends RefCounted
## Small decorations stuck on UI paper: push pin, tape strip, the NEW! burst.
## Art: assets/sprites/ui/stickers/<name>.png (placeholders painted by
## tools/ui/ui_extra_frames.gd; drop final art in by name). Also the wet
## wooden hold slot (frames/hold_slot.png) drawn per grid cell.

const DIR := "res://assets/sprites/ui/stickers/"
const FRAMES_DIR := "res://assets/sprites/ui/frames/"

static var _cache: Dictionary = {}


static func texture(name: String) -> Texture2D:
	if _cache.has(name):
		return _cache[name]
	var tex: Texture2D = null
	for path: String in [DIR + name + ".png", FRAMES_DIR + name + ".png"]:
		if ResourceLoader.exists(path):
			tex = load(path)
			break
	_cache[name] = tex
	return tex


## A sticker as a control placed at `at` (top-left) inside `parent`,
## turned `degrees`; mouse passes through. Null if the art is missing.
static func stick(parent: Control, name: String, at: Vector2, degrees: float = 0.0, scale: float = 1.0) -> TextureRect:
	var tex := texture(name)
	if tex == null:
		return null
	var rect := TextureRect.new()
	rect.texture = tex
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.size = tex.get_size()
	rect.pivot_offset = rect.size * 0.5
	rect.position = at
	rect.rotation_degrees = degrees
	rect.scale = Vector2.ONE * scale
	rect.top_level = false
	parent.add_child(rect)
	return rect


## Draws a sticker centred on `center` from any CanvasItem's _draw.
static func draw(canvas: CanvasItem, name: String, center: Vector2, modulate: Color = Color.WHITE) -> void:
	var tex := texture(name)
	if tex:
		canvas.draw_texture(tex, (center - tex.get_size() * 0.5).round(), modulate)
