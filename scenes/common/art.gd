class_name Art
extends RefCounted
## Real art over the placeholders: `Art.draw(canvas, "restaurant/grill", rect)`
## draws res://assets/sprites/restaurant/grill.png stretched into `rect` (the
## thing's in-game size) and returns true; returns false when the PNG isn't
## there yet, so the caller draws its placeholder instead:
##     if not Art.draw(self, "restaurant/bin", r):
##         ...placeholder drawing...
## Because art always fills the in-game rect, it can be drawn at 1x or 2x
## (see ASSETS.md). Sprite sheets: rows = animations, columns = frames.
## Textures are cached (also "missing"), so checking every frame is cheap.

const PERSON_COLUMNS := 4
## Person sheet rows: walk down / up / left (right = mirrored left), then an
## optional 4th "busy" row (sitting, cooking, grilling).
const ROW_DOWN := 0
const ROW_UP := 1
const ROW_LEFT := 2
const ROW_BUSY := 3

## Where the PNGs live (tests point this elsewhere).
static var root: String = "res://assets/sprites/"
static var _cache: Dictionary = {}  # name -> Texture2D or null


static func texture(sprite: String) -> Texture2D:
	if _cache.has(sprite):
		return _cache[sprite]
	var path := root + sprite + ".png"
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	elif FileAccess.file_exists(path):  # dropped in but not imported yet
		var image := Image.load_from_file(path)
		if image:
			tex = ImageTexture.create_from_image(image)
	_cache[sprite] = tex
	return tex


static func has(sprite: String) -> bool:
	return texture(sprite) != null


## Forget cached lookups (after adding files while the game runs, tests).
static func clear_cache() -> void:
	_cache.clear()


## The whole image stretched into `rect`. False if there's no image.
static func draw(canvas: CanvasItem, sprite: String, rect: Rect2, flip_h: bool = false,
		tint: Color = Color.WHITE) -> bool:
	var tex := texture(sprite)
	if tex == null:
		return false
	canvas.draw_texture_rect(tex, _flipped(rect, flip_h), false, tint)
	return true


## One frame of a sheet with `columns` x `rows` equal frames.
static func draw_frame(canvas: CanvasItem, sprite: String, columns: int, rows: int, column: int, row: int,
		rect: Rect2, flip_h: bool = false, tint: Color = Color.WHITE) -> bool:
	var tex := texture(sprite)
	if tex == null:
		return false
	var frame := Vector2(tex.get_width() / float(columns), tex.get_height() / float(rows))
	var region := Rect2(Vector2(column % columns, clampi(row, 0, rows - 1)) * frame, frame)
	canvas.draw_texture_rect_region(tex, _flipped(rect, flip_h), region, tint)
	return true


## Animated sheet: `columns` frames per row, played at `fps` along `row`;
## frames have the shape of `rect`, so the row count follows from the image
## (a single image is just a 1-column, 1-row sheet).
static func draw_sheet(canvas: CanvasItem, sprite: String, rect: Rect2, columns: int = 1, row: int = 0,
		time: float = 0.0, fps: float = 4.0, flip_h: bool = false) -> bool:
	var tex := texture(sprite)
	if tex == null:
		return false
	var frame_w := tex.get_width() / float(columns)
	var frame_h := frame_w * rect.size.y / rect.size.x
	var rows := maxi(roundi(tex.get_height() / frame_h), 1)
	if columns == 1:  # frames stacked downwards instead
		return draw_frame(canvas, sprite, 1, rows, 0, int(time * fps) % rows, rect, flip_h)
	return draw_frame(canvas, sprite, columns, rows, int(time * fps) % columns, row, rect, flip_h)


## A 16x32 person standing at the canvas origin (feet), from a sheet of
## PERSON_COLUMNS frames per row (frames are twice as tall as wide, so the
## row count follows from the image size). `busy` uses the 4th row if the
## sheet has one.
static func draw_person(canvas: CanvasItem, sprite: String, facing: Vector2i, walk_time: float,
		walking: bool, busy: bool = false, time: float = 0.0) -> bool:
	var tex := texture(sprite)
	if tex == null:
		return false
	var f := person_frame(tex.get_size(), facing, walking, busy, walk_time, time)
	return draw_frame(canvas, sprite, PERSON_COLUMNS, f["rows"], f["column"], f["row"],
		Rect2(-8, -32, 16, 32), f["flip"])


## Which frame of a person sheet of `image_size`: {"rows", "row", "column", "flip"}.
static func person_frame(image_size: Vector2, facing: Vector2i, walking: bool, busy: bool,
		walk_time: float, time: float) -> Dictionary:
	var frame_w := image_size.x / PERSON_COLUMNS
	var rows := maxi(roundi(image_size.y / (frame_w * 2.0)), 1)
	var row := ROW_DOWN
	var flip := false
	if busy and rows > ROW_BUSY:
		row = ROW_BUSY
	elif facing == Vector2i.UP:
		row = ROW_UP
	elif facing.x != 0:
		row = ROW_LEFT
		flip = facing.x > 0
	var column := 0
	if row == ROW_BUSY:
		column = int(time * 4.0) % PERSON_COLUMNS
	elif walking:
		column = int(walk_time * 8.0) % PERSON_COLUMNS
	return {"rows": rows, "row": mini(row, rows - 1), "column": column, "flip": flip}


## A rect with negative width draws mirrored.
static func _flipped(rect: Rect2, flip_h: bool) -> Rect2:
	if not flip_h:
		return rect
	return Rect2(rect.position.x + rect.size.x, rect.position.y, -rect.size.x, rect.size.y)
