class_name HelpGridView
extends GridContainer
## Renders one HelpEntries tab: a grid of group cards, each with an icon
## header and rows of key caps (or a picture) + a short caption.

const CAPTION_SIZE: int = 10


func _init() -> void:
	columns = 3
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("h_separation", 6)
	add_theme_constant_override("v_separation", 6)


func show_tab(tab: Dictionary) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var groups: Array = tab.get("groups", [])
	for group: Dictionary in groups:
		add_child(_group(group))
	UiFx.stagger(self, 0.04)


func _group(group: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.theme_type_variation = &"PaperPanel"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiFx.tilt(card, [0.8, -0.6, 0.4, -0.9, 0.6, -0.4][get_child_count() % 6])  # pinned notes
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	card.add_child(box)
	var header := UiIcons.pair(str(group.get("icon", "info")), str(group.get("title", "")), 14,
		UiIcons.RED, &"HeadingLabel", 12)
	box.add_child(header)
	var rows: Array = group.get("rows", [])
	for row: Array in rows:
		box.add_child(_row(str(row[0]), str(row[1])))
	return card


func _row(keys: String, caption: String) -> HBoxContainer:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 3)
	var caps := HBoxContainer.new()
	caps.add_theme_constant_override("separation", 2)
	caps.custom_minimum_size.x = 42
	line.add_child(caps)
	if keys.begins_with("@"):
		caps.add_child(UiIcons.make(keys.substr(1), 12, Color("be772b")))
	else:
		for key in keys.split(" "):
			var cap := Label.new()
			cap.theme_type_variation = &"KeyLabel"
			cap.add_theme_font_size_override("font_size", 9)
			cap.text = key
			caps.add_child(cap)
	var label := Label.new()
	label.theme_type_variation = &"InkLabel"
	label.text = caption
	label.add_theme_font_size_override("font_size", CAPTION_SIZE)
	line.add_child(label)
	return line
