class_name PhoneFrame
extends RefCounted
## Hardware bits of Rin's phone around the app (PhoneApp): camera dot in the
## bezel, side buttons, signal + battery in the status bar, and the app's
## icon tab buttons (flat app tabs like the Review app, tooltip = name).
## Final art: ui/frames/phone_status (signal + battery, 24x8) via Art.

const INK := Color("090a14")
const BEZEL := Color("394a50")
const GLOW := Color("5ff2e0")
const SCREEN := Color("ebede9")
const TAB_SIZE := Vector2(28, 22)


static func dress(phone: Control, status_bar: HBoxContainer) -> void:
	phone.draw.connect(func() -> void:
		var h := phone.size.y
		# Front camera on the left bezel (phone held sideways), side keys on top.
		phone.draw_rect(Rect2(4, h * 0.5 - 3.0, 4, 6), INK)
		phone.draw_rect(Rect2(5, h * 0.5 - 2.0, 2, 2), Color("4f8fba"))
		for x: float in [60.0, 84.0, phone.size.x - 70.0]:
			phone.draw_rect(Rect2(x, -2, 18 if x < 100.0 else 26, 2), BEZEL)
			phone.draw_rect(Rect2(x, -3, 18 if x < 100.0 else 26, 1), INK))
	status_bar.draw.connect(func() -> void:  # thin rule under the status bar
		status_bar.draw_rect(Rect2(0, status_bar.size.y + 2.0, status_bar.size.x, 1), Color("3c5e8b")))
	var icons := Control.new()
	icons.custom_minimum_size = Vector2(26, 8)
	icons.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icons.draw.connect(func() -> void: _draw_status(icons))
	status_bar.add_child(icons)


## Three signal bars + a battery at 3/4.
static func _draw_status(view: Control) -> void:
	if Art.draw(view, "ui/frames/phone_status", Rect2(Vector2.ZERO, view.size)):
		return
	for i in 3:
		var bar_h := 3.0 + i * 2.0
		view.draw_rect(Rect2(i * 3.0, 8.0 - bar_h, 2, bar_h), SCREEN)
	var body := Rect2(11, 1, 12, 7)
	view.draw_rect(body, SCREEN, false, 1.0)
	view.draw_rect(Rect2(body.end.x, 3, 1, 3), SCREEN)
	view.draw_rect(Rect2(body.position + Vector2(2, 2), Vector2(6, 3)), GLOW)


## Icon-only toggle tab in `row`; `on_pressed` runs on click.
static func tab_button(icon: String, words: String, row: HBoxContainer, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = words
	button.custom_minimum_size = TAB_SIZE
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiIcons.dress(button, icon, 14, UiIcons.CHALK)
	for state: String in ["normal", "hover", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, SocialStyle.frame("social_tab_off", 2))
	for state: String in ["pressed", "hover_pressed"]:
		button.add_theme_stylebox_override(state, SocialStyle.frame("social_tab_on", 2))
	button.pressed.connect(on_pressed)
	UiFx.hover_lift(button, 0.08)
	row.add_child(button)
	return button
