class_name ReelBar
extends CanvasLayer
## A tiny line-tension bar just under the crosshair while reeling (the rod
## bend and the line colour say the same thing in the world).

const SIZE := Vector2(40, 3)

var _back := ColorRect.new()
var _fill := ColorRect.new()


func _ready() -> void:
	layer = 5
	for rect: ColorRect in [_back, _fill]:
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.anchor_left = 0.5
		rect.anchor_right = 0.5
		rect.anchor_top = 0.5
		rect.anchor_bottom = 0.5
		add_child(rect)
	_back.color = Color(0, 0, 0, 0.45)
	_back.offset_left = -SIZE.x * 0.5 - 1
	_back.offset_right = SIZE.x * 0.5 + 1
	_back.offset_top = 14
	_back.offset_bottom = 14 + SIZE.y + 2
	_fill.offset_top = 15
	_fill.offset_bottom = 15 + SIZE.y
	show_tension(-1.0)


## -1 hides it.
func show_tension(value: float) -> void:
	visible = value >= 0.0
	if not visible:
		return
	var t := clampf(value, 0.0, 1.0)
	_fill.offset_left = -SIZE.x * 0.5
	_fill.offset_right = -SIZE.x * 0.5 + SIZE.x * t
	_fill.color = Color("e7e2cf").lerp(Color("e0402f"), t)
