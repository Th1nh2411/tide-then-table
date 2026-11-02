class_name RestaurantSetup3D
extends RefCounted
## One-time wiring of the 3D restaurant's UI and tools (called from
## RestaurantScene3D._ready, in this order): panels + HUD + goals + social +
## pause menu + phone, then the cat's dialogue box, quest tracker, Nhịp Sóng
## and the cooking overlay, then the day (open_day).


static func build_ui(host: RestaurantScene3D) -> void:
	host.panels.build()
	var hud := RestaurantHud3D.new()
	host.hud = hud
	host.add_child(hud)
	hud.setup(host, RestaurantPanels3D.ui_theme(), RestaurantPanels3D.panel_style())
	hud.close_requested.connect(host._close_early)
	host.goals = RestaurantGoals3D.new(host)
	host.goals.build()
	host.social = RestaurantSocial3D.new(host)
	host.social.build()
	host.add_child(load("res://scenes/ui/pause_menu.tscn").instantiate())
	host.add_child(load("res://scenes/ui/phone_app.tscn").instantiate())


static func build_tools(host: RestaurantScene3D) -> void:
	host.cat_dialogue = DialogueBox.new()
	host.add_child(host.cat_dialogue)
	var tracker := QuestTracker.new()
	tracker.catalog = host.fish_catalog
	tracker.origin = Vector2(6, 56)
	tracker.hidden_when = func() -> bool: return host.modal_open() or host.panels.summary_visible()
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
## Horror build: no menu planning. An empty MenuPlan keeps older code paths
## harmless (nothing reserved, nothing to return); orders come from
## RestaurantService3D.FIXED_MENU.
static func open_day(host: RestaurantScene3D) -> void:
	host.plan = MenuPlan.new(3)
	(host.get_node("WorldMenuBoard") as WorldMenuBoard3D).bind(host.plan, host.menu)
	DayClock.set_progress(0.0, DayClock.shop_open_hour, DayClock.shop_close_hour)
