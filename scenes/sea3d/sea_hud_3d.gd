class_name SeaHud3D
extends RefCounted
## HUD (SeaHudView3D: icon chips, key caps, speech strip), the pause menu,
## edge navigation and first-time guides of the 3D sea.
## Host (SeaScene3D) fields written: hud_view, message, navigation.

static func build_hud(sea: SeaScene3D) -> void:
	var layer := CanvasLayer.new()
	sea.add_child(layer)
	sea.hud_view = SeaHudView3D.new()
	layer.add_child(sea.hud_view)
	# The current Rin's line (SeaScene3D._say queue); the view shows it on
	# its speech strip.
	sea.message = Label.new()
	sea.message.visible = false
	layer.add_child(sea.message)

static func build_shared_ui(sea: SeaScene3D) -> void:
	var pause := load("res://scenes/ui/pause_menu.tscn") as PackedScene
	if pause:
		sea.add_child(pause.instantiate())

static func update(sea: SeaScene3D) -> void:
	sea._next_line()
	sea.hud_view.refresh(sea)

static func build_navigation(sea: SeaScene3D) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 2
	sea.add_child(layer)
	var navigation: Control = preload("res://scenes/sea3d/sea_navigation_3d.gd").new()
	navigation.set("world", sea)
	navigation.set("camera", sea.camera)
	layer.add_child(navigation)
	sea.navigation = navigation
	var guide := Guide.new()
	guide.blocked = func() -> bool: return sea.fishing or sea.ending
	sea.add_child(guide)
	# No pointer to shoals: the hint is the bubbles themselves.
	guide.add("sea3d_bubbles", "Tìm bọt khí trên mặt biển", func() -> bool: return not sea.fishing and sea._casts_used_total() == 0,
		func() -> Vector2: return navigation.call("screen_point", sea.boat.position + Vector3(0, 3.0, 0)),
		func() -> bool: return sea.fishing or sea._casts_used_total() > 0)

static func navigation_targets(sea: SeaScene3D) -> Array[Dictionary]:
	var targets: Array[Dictionary] = [{"pos": sea.START, "label": "Bến", "color": "f2d98a"}]
	for entry: Array in [[sea.SHRINE_POS, "Miếu"], [sea.HUT_POS, "Ông Tám"], [sea.LIGHTHOUSE_POS, "Hải đăng"], [sea.RAFT_POS, "Bè tôm"]]:
		var pos: Vector3 = entry[0]
		if sea.boat.position.distance_to(pos) < 20.0:
			targets.append({"pos": pos, "label": entry[1], "color": "c6b89a"})
	if Story.is_fog_open():
		targets.append({"pos": sea.WHIRLPOOL_POS, "label": "???", "color": "5ff2e0"})
	return targets
