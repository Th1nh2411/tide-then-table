class_name PhoneDex
extends RefCounted
## Dex screen of the phone: "3/7" + the next reward, then a grid of fish
## tiles. Known fish show their picture, count and record; unknown ones a
## dark silhouette with "?" and "???"; aberrant names glitch. A fish seen in
## the Dex for the first time gets a "NEW" stamp and the camera shutter
## (story flag "dex_shown_<id>", saved).

const FLAG_PREFIX := "dex_shown_"
const COLUMNS := 4


static func fill(box: VBoxContainer, catalog: FishCatalog) -> void:
	var known := 0
	for fish in catalog.fish:
		known += 1 if int(GameState.caught_species.get(fish.id, 0)) > 0 else 0
	var head := PhoneCards.header(box, "dex", "%d/%d" % [known, catalog.fish.size()])
	var reward := PhoneCards.neo(CollectionRewards.next_milestone_text(), 8, Color("819796"))
	head.add_child(reward)
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	box.add_child(grid)
	var fresh := false
	for fish in catalog.fish:
		var tile := _tile(fish)
		grid.add_child(tile)
		if int(GameState.caught_species.get(fish.id, 0)) > 0 and not GameState.has_flag(FLAG_PREFIX + fish.id):
			GameState.set_flag(FLAG_PREFIX + fish.id)
			_stamp_new(tile)
			fresh = true
	if fresh:
		Sfx.play("shutter")


static func _tile(fish: FishData) -> PanelContainer:
	var caught := int(GameState.caught_species.get(fish.id, 0))
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"AppCardPanel"
	panel.custom_minimum_size = Vector2(64, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	panel.add_child(box)
	var window := PanelContainer.new()  # the fish on a small sea-blue window
	var sea := StyleBoxFlat.new()
	sea.bg_color = Color("172038")
	sea.anti_aliasing = false
	window.add_theme_stylebox_override("panel", sea)
	box.add_child(window)
	var pic := PhoneCards.picture(fish, Vector2(52, 26))
	pic.silhouette = 0.0 if caught > 0 else 1.0
	pic.mystery = caught == 0
	pic.tooltip_text = fish.display_name if caught > 0 else "???"
	window.add_child(pic)
	var fish_name := "???"
	if caught > 0:
		fish_name = PhoneReports.glitch(fish.display_name, GameState.day) if fish.is_aberrant else fish.display_name
	var label := PhoneCards.neo(fish_name, 8, Color("a53030") if fish.is_aberrant and caught > 0 else PhoneCards.INK)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.clip_text = true
	box.add_child(label)
	if caught > 0:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 3)
		row.add_child(PhoneCards.neo("x%d" % caught, 8, Color("253a5e")))
		if fish.catch_method == FishData.CatchMethod.ROD and GameState.best_size(fish) > 0.0:
			row.add_child(PhoneCards.icon_text("trophy", fish.weight_text(GameState.best_size(fish)), Color("de9e41")))
		box.add_child(row)
	return panel


## "NEW" red stamp slammed onto a tile seen for the first time.
static func _stamp_new(tile: Control) -> void:
	var stamp := Label.new()
	stamp.text = "NEW"
	stamp.theme_type_variation = &"BadgeLabel"
	stamp.add_theme_font_size_override("font_size", 8)
	stamp.position = Vector2(30, -2)
	stamp.top_level = false
	var holder := Control.new()  # outside the container layout
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(stamp)
	tile.add_child(holder)
	UiFx.tilt(stamp, -12.0)
	UiFx.stamp(stamp, null, 0.25)
