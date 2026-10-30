class_name UiFx
extends RefCounted
## Small UI animations shared by every screen. All tweens live on the control
## (die with it) and keep running while the tree is paused (menus pause it).
## Buttons get a press squash automatically (`hook_buttons`, from SceneRouter).

const POP_SECONDS: float = 0.22


static func _tween(node: Node) -> Tween:
	var tween := node.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	return tween


## Pivot in the middle so scale animations grow from the centre.
static func _center_pivot(control: Control) -> void:
	control.pivot_offset = control.size * 0.5


## Scale up from small with a little overshoot, fading in.
static func pop_in(control: Control, delay: float = 0.0) -> Tween:
	_center_pivot(control)
	control.scale = Vector2.ONE * 0.6
	control.modulate.a = 0.0
	var tween := _tween(control).set_parallel()
	tween.tween_property(control, "scale", Vector2.ONE, POP_SECONDS).set_delay(delay) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "modulate:a", 1.0, POP_SECONDS * 0.7).set_delay(delay)
	return tween


## Slide in from `offset` (pixels) to its current position, fading in.
static func slide_in(control: Control, offset: Vector2, delay: float = 0.0, seconds: float = 0.28) -> Tween:
	var home := control.position
	control.position = home + offset
	control.modulate.a = 0.0
	var tween := _tween(control).set_parallel()
	tween.tween_property(control, "position", home, seconds).set_delay(delay) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "modulate:a", 1.0, seconds * 0.8).set_delay(delay)
	return tween


## Pops each child of `box` in turn (lists, card grids, summary rows).
static func stagger(box: Control, step: float = 0.05, delay: float = 0.0) -> void:
	var i := 0
	for child in box.get_children():
		var control := child as Control
		if control and control.visible:
			pop_in(control, delay + step * i)
			i += 1


## Counts a number up/down on a label: `format` gets the current int ("%dk").
static func count_to(label: Label, from: int, to: int, format: String = "%d", seconds: float = 0.6) -> Tween:
	var tween := _tween(label)
	tween.tween_method(func(v: float) -> void: label.text = format % roundi(v), float(from), float(to), seconds) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return tween


## Quick squash-and-stretch (button press, coin gained, item added).
static func bounce(control: Control, amount: float = 0.12) -> Tween:
	_center_pivot(control)
	var tween := _tween(control)
	tween.tween_property(control, "scale", Vector2(1.0 + amount, 1.0 - amount), 0.06)
	tween.tween_property(control, "scale", Vector2(1.0 - amount * 0.5, 1.0 + amount * 0.5), 0.07)
	tween.tween_property(control, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tween


## Side-to-side shake (warning: a guest about to leave, not enough money).
static func shake(control: Control, pixels: float = 3.0) -> Tween:
	var home := control.position
	var tween := _tween(control)
	for i in 4:
		tween.tween_property(control, "position:x", home.x + (pixels if i % 2 == 0 else -pixels), 0.04)
	tween.tween_property(control, "position:x", home.x, 0.04)
	return tween


## Flash a tint and back (highlight a changed value).
static func flash(control: CanvasItem, color: Color = Color(1.6, 1.4, 0.8)) -> Tween:
	var tween := _tween(control)
	tween.tween_property(control, "modulate", color, 0.08)
	tween.tween_property(control, "modulate", Color.WHITE, 0.3)
	return tween


## Gentle endless pulse (call-to-action). Returns the looping tween.
static func pulse(control: Control, amount: float = 0.05, seconds: float = 0.9) -> Tween:
	_center_pivot(control)
	var tween := _tween(control).set_loops()
	tween.tween_property(control, "scale", Vector2.ONE * (1.0 + amount), seconds * 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(control, "scale", Vector2.ONE, seconds * 0.5).set_trans(Tween.TRANS_SINE)
	return tween


## Every BaseButton added to the tree squashes when pressed.
static func hook_buttons(tree: SceneTree) -> void:
	tree.node_added.connect(func(node: Node) -> void:
		var button := node as BaseButton
		if button and not button.has_meta("ui_fx_hooked"):
			button.set_meta("ui_fx_hooked", true)
			button.button_down.connect(func() -> void:
				if is_instance_valid(button) and button.is_inside_tree():
					bounce(button, 0.08)))
