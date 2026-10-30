class_name RestaurantSetup3D
extends RefCounted
## One-time wiring of the 3D restaurant's UI and tools (called from
## RestaurantScene3D._ready, in this order): panels + HUD + goals + social +
## pause menu + phone, then the cat's dialogue box, quest tracker, Nhịp Sóng
## and the cooking overlay, then today's menu plan and the planning panel.


static func build_ui(host: RestaurantScene3D) -> void:
	host.panels.build()
	host.planning_panel = host.panels.planning
	var hud := RestaurantHud3D.new()
	host.hud = hud
	host.add_child(hud)
	hud.setup(host, RestaurantPanels3D.ui_theme(), RestaurantPanels3D.panel_style())
	hud.menu_requested.connect(host._toggle_planning)
	hud.renovate_requested.connect(host._open_renovation)
	hud.close_requested.connect(host._close_early)
	hud.sail_requested.connect(host._sail)
	host.goals = RestaurantGoals3D.new(host)
	host.goals.build()
	host.social = RestaurantSocial3D.new(host)
	host.social.build()
	host.add_child(load("res://scenes/ui/pause_menu.tscn").instantiate())
	host.add_child(load("res://scenes/ui/phone_app.tscn").instantiate())
	host.bag.build_fridge(host)
	host.panels.refresh_market()


static func build_tools(host: RestaurantScene3D) -> void:
	host.cat_dialogue = DialogueBox.new()
	host.add_child(host.cat_dialogue)
	var tracker := QuestTracker.new()
	tracker.catalog = host.fish_catalog
	tracker.origin = Vector2(6, 56)
	tracker.hidden_when = func() -> bool: return host.modal_open() or host.panels.summary_visible() \
		or (host.story_bridge != null and host.story_bridge.playing)
	host.add_child(tracker)
	var wave := WavePower.new()
	wave.seconds = 4.0
	wave.keep_rin_speed = true
	wave.can_use = func() -> bool: return host.shift_running and not host.shift_over
	host.wave_power = wave
	host.add_child(wave)
	var overlay: CookingOverlay = load("res://scenes/restaurant/cooking/cooking_overlay.tscn").instantiate()
	overlay.kitchen_upgrade = host.kitchen_upgrade
	overlay.finished.connect(host.interaction.on_cooking_finished)
	overlay.spilled.connect(host.interaction.on_cooking_spilled)
	host.cooking_overlay = overlay
	host.add_child(overlay)


## Today's plan (dish slots grow with the kitchen) and the planning panel, opened.
static func open_planning(host: RestaurantScene3D) -> void:
	var plan := MenuPlan.new(3 + mini(DishBook.kitchen_level(), 2))
	plan.kitchen_level = DishBook.kitchen_level()
	host.plan = plan
	(host.get_node("WorldMenuBoard") as WorldMenuBoard3D).bind(plan, host.menu)
	DayClock.set_progress(0.0, DayClock.shop_open_hour, DayClock.shop_close_hour)
	DailyTrend.ensure(null, host.menu)
	var panel: MenuPanel3D = host.planning_panel
	panel.setup(plan, host.menu, host.market_stock, host._has_stock, RestaurantPanels3D.ui_theme(),
		RestaurantPanels3D.panel_style())
	panel.shop_requested.connect(host._open_market)
	panel.open_requested.connect(host._open_shift)
	panel.renovate_requested.connect(host._open_renovation)
	panel.sail_requested.connect(host._sail_without_shift)
	panel.open()
