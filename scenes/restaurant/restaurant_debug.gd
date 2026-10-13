class_name RestaurantDebug
extends Node
## Debug-build keys so the restaurant can be tested with F6 without a sea
## trip: F1 while planning the menu adds one of every fish to storage; F2
## (any time) puts a bulk buy of every drink straight into the fridge.
## F3 / F4 (cutscenes, Nhịp Sóng): CutsceneDebug.

signal message_requested(text: String)

var menu_panel: MenuSetupPanel
var plan: MenuPlan
var fish_catalog: FishCatalog
var stall: MarketStall


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not OS.is_debug_build() or key == null or not key.pressed or key.echo:
		return
	if key.physical_keycode == KEY_F1 and menu_panel.visible:
		for fish in fish_catalog.fish:
			GameState.storage.append(InventoryItem.new(fish, 1.0))
		plan.changed.emit()  # refresh the menu panel
	elif key.physical_keycode == KEY_F2:
		for dish in stall.products:
			if dish.instant_serve:
				var units := dish.buy_units(dish.has_bulk())
				stall.stock.add(dish, units)
				message_requested.emit("[debug] +%d %s %s vào tủ lạnh" % [units, dish.unit_name, dish.display_name])
