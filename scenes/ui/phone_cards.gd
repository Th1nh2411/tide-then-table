class_name PhoneCards
extends ScrollContainer
## Icon-first app screens for the phone's text tabs (storage, menu, dex,
## boat, ledger): flat white app cards ("AppCardPanel") with fish / dish
## pictures, coin chips, bars and a small chart, VT323 for the few words.
## The full text (PhoneReports) stays on the phone's ContentLabel (tests,
## and the tooltip of the screen). Dex grid: PhoneDex; ledger: PhoneLedger.

const INK := Color("090a14")
const RED := Color("a53030")
const SEA := Color("253a5e")
const GREEN := Color("468232")

var _box: VBoxContainer


func _ready() -> void:
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_box = VBoxContainer.new()
	_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_box.add_theme_constant_override("separation", 4)
	add_child(_box)


## Rebuilds the screen for a tab (PhoneApp tab index).
func show_tab(index: int, app: PhoneApp) -> void:
	for child in _box.get_children():
		child.queue_free()
	scroll_vertical = 0
	match index:
		0: _storage(app.fridge_loss())
		1: _menu(app.menu)
		3: PhoneDex.fill(_box, app.fish_catalog)
		4: _boat(app)
		_: PhoneLedger.fill(_box)
	UiFx.stagger(_box, 0.03)


# --- shared pieces -------------------------------------------------------

static func neo(text: String, size: int = 10, color: Color = INK) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"NeoLabel"
	label.add_theme_font_size_override("font_size", roundi(size * PhoneApp.NEO_FONT_SCALE))
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


## A white app card holding a row; returns the row.
static func card(parent: Control, separation: int = 6) -> HBoxContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"AppCardPanel"
	parent.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", separation)
	panel.add_child(row)
	return row


static func spacer(row: Control) -> void:
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(gap)


## Icon + VT323 text in ink on a card.
static func icon_text(icon: String, text: String, icon_color: Color, color: Color = INK) -> HBoxContainer:
	var chip := UiIcons.pair(icon, text, 12, icon_color, &"NeoLabel", roundi(10 * PhoneApp.NEO_FONT_SCALE))
	(chip.get_node("Text") as Label).add_theme_color_override("font_color", color)
	return chip


## Coin + "70k" chip.
static func coin(text: String, color: Color = RED) -> HBoxContainer:
	return icon_text("money", text, Color("de9e41"), color)


static func header(parent: Control, icon: String, text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	parent.add_child(row)
	row.add_child(UiIcons.make(icon, 14, Color("5ff2e0")))
	row.add_child(neo(text, 11, Color("5ff2e0")))
	return row


static func picture(fish: FishData, size: Vector2 = Vector2(32, 18)) -> FishPortrait:
	var pic := FishPortrait.new()
	pic.fish = fish
	pic.custom_minimum_size = size
	pic.tooltip_text = fish.display_name
	pic.mouse_filter = Control.MOUSE_FILTER_PASS
	return pic


static func meter(value: float, color: Color, width: float = 40.0) -> MeterBar:
	var bar := MeterBar.new()
	bar.color = color
	bar.custom_minimum_size = Vector2(width, 6)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.value = clampf(value, 0.0, 1.0)
	return bar


# --- tabs ----------------------------------------------------------------

## One card per fish + freshness: picture, count, freshness bar, price x, nights left.
func _storage(fridge_loss: float) -> void:
	header(_box, "crate", "%d" % GameState.storage.size())
	if GameState.storage.is_empty():
		card(_box).add_child(neo("Trống", 10, Color("577277")))
		return
	var groups: Dictionary = {}  # "id|freshness" -> [FishData, count, freshness]
	for item: InventoryItem in GameState.storage:
		var key := "%s|%d" % [item.fish.id, roundi(item.freshness)]
		if not groups.has(key):
			groups[key] = [item.fish, 0, item.freshness]
		groups[key][1] = int(groups[key][1]) + 1
	for key: String in groups:
		var entry: Array = groups[key]
		var freshness: float = entry[2]
		var nights := ceili(freshness / fridge_loss) - 1 if fridge_loss > 0.0 else 99
		var row := card(_box)
		row.add_child(picture(entry[0] as FishData))
		row.add_child(neo("x%d" % int(entry[1]), 11))
		row.add_child(meter(freshness / 100.0, GREEN if freshness > 50.0 else Color("de9e41")))
		row.add_child(neo("x%.1f" % KitchenLogic.freshness_multiplier(freshness), 10, SEA))
		spacer(row)
		var moon := icon_text("moon", str(maxi(nights, 0)), RED if nights <= 0 else SEA)
		moon.tooltip_text = "Hỏng đêm nay" if nights <= 0 else "Còn %d đêm" % nights
		moon.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(moon)


## Dish cards: picture, price, portions (or the missing seafood).
func _menu(menu: DishCatalog) -> void:
	header(_box, "menu", "Menu")
	var counts := KitchenLogic.count_by_fish(GameState.storage)
	for dish in menu.dishes:
		if dish.always_available and not dish.on_menu_today():
			continue
		if not dish.always_available and not DishBook.is_cookable(dish):
			continue
		var row := card(_box, 4)
		row.tooltip_text = dish.display_name
		var plate := RestCardView.DishIcon.new()
		plate.dish = dish
		row.add_child(plate)
		row.add_child(neo(dish.display_name, 10))
		spacer(row)
		if dish.always_available:
			row.add_child(UiIcons.make("check", 12, GREEN))
		else:
			var portions := MenuPlan.max_portions(dish, GameState.storage)
			if portions > 0:
				var pips := PipBar.new()
				pips.pip_color = Color("de9e41")
				pips.empty_color = Color(INK, 0.2)
				pips.max_pips = 8
				pips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				row.add_child(pips)
				pips.set_count(portions)
			else:
				for fish_id in dish.ingredients:
					var short := int(dish.ingredients[fish_id]) - int(counts.get(fish_id, 0))
					if short > 0:
						row.add_child(neo("-%d %s" % [short, fish_id.replace("_", " ")], 9, RED))
		row.add_child(coin("%dk" % dish.base_price))


## Boat card: hull bar, hold size, lamp oil, range; then upgrade levels.
func _boat(app: PhoneApp) -> void:
	var boat: BoatData = GameState.get_upgrade_value(app.boat_upgrade)
	header(_box, "boat", boat.display_name)
	var hull := card(_box, 4)
	hull.add_child(UiIcons.make("hammer", 12, SEA))
	hull.add_child(meter(GameState.boat_hp / 100.0, RED if BoatCondition.is_broken() else GREEN, 70.0))
	hull.add_child(neo("%d%%" % roundi(GameState.boat_hp), 10))
	spacer(hull)
	hull.add_child(coin("%dk" % BoatCondition.full_repair_cost(boat)))
	var stats := card(_box, 4)
	stats.add_child(UiIcons.make("crate", 12, SEA))
	stats.add_child(neo("%dx%d" % [boat.hold_size.x, boat.hold_size.y], 10))
	stats.add_child(UiIcons.make("oil", 12, SEA))
	stats.add_child(neo("%d" % roundi(float(GameState.get_upgrade_value(app.lamp_upgrade))), 10))
	stats.add_child(UiIcons.make("map", 12, SEA))
	stats.add_child(neo(boat.range_label, 9))
	for upgrade in app.upgrades:
		var level := GameState.get_upgrade_level(upgrade.id)
		var row := card(_box, 4)
		row.tooltip_text = "%s: %s" % [upgrade.display_name, upgrade.label_at(level)]
		row.add_child(UiIcons.make(PhoneShop.icon_for(upgrade), 12, SEA))
		row.add_child(neo(upgrade.display_name, 10))
		spacer(row)
		var pips := PipBar.new()
		pips.pip_color = Color("4f8fba")
		pips.empty_color = Color(INK, 0.25)
		pips.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(pips)
		pips.set_count(level, upgrade.max_level())
