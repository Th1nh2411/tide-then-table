class_name RestaurantSetup3D
extends RefCounted
## One-time wiring of the 3D restaurant's UI (called from
## RestaurantScene3D._ready): panels + HUD + pause menu, then the day (open_day).


static func build_ui(host: RestaurantScene3D) -> void:
	host.panels.build()
	var hud := RestaurantHud3D.new()
	host.hud = hud
	host.add_child(hud)
	hud.setup(host, RestaurantPanels3D.ui_theme(), RestaurantPanels3D.panel_style())
	hud.close_requested.connect(host._close_early)
	host.add_child(load("res://scenes/ui/pause_menu.tscn").instantiate())


## Horror build: no menu planning; the board shows the fixed menu.
static func open_day(host: RestaurantScene3D) -> void:
	(host.get_node("WorldMenuBoard") as WorldMenuBoard3D).show_dishes(RestaurantService3D.FIXED_MENU.dishes)
	DayClock.set_progress(0.0, DayClock.shop_open_hour, DayClock.shop_close_hour)
