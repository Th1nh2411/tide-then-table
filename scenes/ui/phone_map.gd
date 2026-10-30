class_name PhoneMap
extends Control
## Map tab of the phone app. The sea scene captures its layout (zones, land,
## islands/rocks, dock, places) into a static snapshot, so the map also works
## from the restaurant, plus the current boat's range line. Live extras at
## sea: the boat (group "boat") and nets (group "net_buoys"). Click to add/remove a pin (GameState.map_pins);
## pins also show as edge markers at sea.

const PIN_HIT_RADIUS_PX: float = 8.0

## Chart paper + palette tones (Xóm Đèn).
@export var paper: Color = Color("e7d5b3")
@export var land_color: Color = Color("c09473")
@export var rock_color: Color = Color("577277")
@export var zone_label_color: Color = Color("ebede9")
## Sea tones a zone color snaps to, deep to shallow.
@export var sea_tones: Array[Color] = [Color("172038"), Color("253a5e"), Color("3c5e8b"), Color("4f8fba"), Color("73bed3")]
@export var label_size: int = 7
## Big map (MapOverlay): legend row + zone names.
@export var show_legend: bool = false
## Distance shown in "m" like the sea's edge markers.
@export var pixels_per_meter: float = 10.0

## Layout of the sea map, filled by capture(). Empty until the first night.
static var _snap: Dictionary = {}


## Called by the sea scene once its nodes are ready.
static func capture(map_size: Vector2, zones_root: Node, land_root: Node, obstacles_root: Node,
		dock: Node2D, whirlpool_pos: Vector2, places: Array[Node], range_y: float = -INF) -> void:
	var zones: Array = []
	for child in zones_root.get_children():
		var zone := child as SeaZone
		if zone:
			zones.append({"rect": zone.get_global_rect(), "color": zone.color,
				"fog": zone.zone == FishData.Zone.FOG, "name": PhoneReports.ZONE_NAMES[zone.zone]})
	var land: Array = []
	for child in land_root.get_children():
		var block := child as LandBlock
		if block:
			land.append(Rect2(block.global_position, block.size))
	var rocks: Array = []
	for child in obstacles_root.get_children():
		var rock := child as Rock
		# Submerged rocks are unknown to the map.
		if rock and not rock.submerged:
			rocks.append({"pos": rock.global_position, "radius": rock.radius, "color": rock.color})
	var poi_list: Array = []
	for place in places:
		var poi := place as PointOfInterest
		if poi:
			poi_list.append({"pos": poi.global_position, "label": poi.map_label if poi.map_label else poi.title})
	_snap = {"size": map_size, "zones": zones, "land": land, "rocks": rocks,
		"dock": dock.global_position, "whirlpool": whirlpool_pos, "places": poi_list, "range_y": range_y}


static func has_snapshot() -> bool:
	return not _snap.is_empty()


## Adds a pin at `world_pos`, or removes the pin within `hit_radius` of it.
## Returns true if a pin was added. Does nothing when full (MAX_PINS).
static func toggle_pin(world_pos: Vector2, hit_radius: float) -> bool:
	for i in GameState.map_pins.size():
		var pin: Vector2 = GameState.map_pins[i]
		if pin.distance_to(world_pos) <= hit_radius:
			GameState.map_pins.remove_at(i)
			return false
	if GameState.map_pins.size() >= GameState.MAX_PINS:
		return false
	GameState.map_pins.append(world_pos)
	return true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(0, 210)


func _process(_delta: float) -> void:
	if is_visible_in_tree():
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT and has_snapshot():
		accept_event()
		var scale_px := _scale()
		toggle_pin(_to_world(click.position), PIN_HIT_RADIUS_PX / scale_px)


func _draw() -> void:
	var font := _font()
	draw_rect(Rect2(Vector2.ZERO, size), paper)
	draw_rect(Rect2(Vector2.ZERO, size), MapSymbols.INK, false, 2.0)
	if not has_snapshot():
		draw_string(font, Vector2(8, 20), "Chưa có dữ liệu bản đồ. Ra khơi một lần để đồng bộ.",
			HORIZONTAL_ALIGNMENT_LEFT, size.x - 16, label_size, MapSymbols.INK)
		return
	var fog_open := Story.is_fog_open()
	for zone: Dictionary in _snap["zones"]:
		if zone["fog"] and not fog_open:
			continue
		draw_rect(_to_map_rect(zone["rect"]), _sea_tone(zone["color"]))
	_draw_grid()
	for rect: Rect2 in _snap["land"]:
		var land := _to_map_rect(rect)
		draw_rect(land, land_color)
		draw_line(land.position, Vector2(land.end.x, land.position.y), MapSymbols.INK, 2.0)
	for rock: Dictionary in _snap["rocks"]:
		MapSymbols.dot(self, _to_map(rock["pos"]), maxf(float(rock["radius"]) * _scale(), 1.5), rock_color)
	draw_rect(_to_map_rect(Rect2(Vector2.ZERO, _snap["size"])), MapSymbols.INK, false, 1.0)
	if show_legend:
		for zone: Dictionary in _snap["zones"]:
			if zone.has("name") and (not zone["fog"] or fog_open):
				var r := _to_map_rect(zone["rect"])
				draw_string(font, r.position + Vector2(4, label_size + 3), zone["name"], HORIZONTAL_ALIGNMENT_LEFT, -1,
					label_size, Color(zone_label_color, 0.8))
	_draw_range(font)
	_draw_story_marks(font, fog_open)
	MapSymbols.dock(self, _to_map(_snap["dock"]))
	for place: Dictionary in _snap["places"]:
		var at := _to_map(place["pos"])
		MapSymbols.dot(self, at, 2.0, MapSymbols.PLACE)
		MapSymbols.label(self, font, at + Vector2(5, 3), place["label"], label_size)
	for buoy: Node2D in get_tree().get_nodes_in_group("net_buoys"):
		MapSymbols.dot(self, _to_map(buoy.global_position), 2.0, MapSymbols.NET)
	for i in GameState.map_pins.size():
		MapSymbols.pin(self, font, _to_map(GameState.map_pins[i]), i + 1, label_size)
	var boat := get_tree().get_first_node_in_group("boat") as Node2D
	if boat:
		MapSymbols.boat(self, _to_map(boat.global_position), boat.global_rotation)
	var hint := "Ghim %d/%d" % [GameState.map_pins.size(), GameState.MAX_PINS]
	if boat:
		var meters := roundi(boat.global_position.distance_to(_snap["dock"]) / pixels_per_meter)
		hint += " · về bến %dm" % meters
	draw_string(font, Vector2(6, size.y - 5), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, MapSymbols.INK)
	if show_legend:
		MapSymbols.legend(self, font, size.x - 6.0, size.y - 5, label_size)


## Chart grid: faint ink lines every sixth of the map.
func _draw_grid() -> void:
	var area := _to_map_rect(Rect2(Vector2.ZERO, _snap["size"]))
	var line := Color(MapSymbols.INK, 0.12)
	for i in range(1, 6):
		var x := roundf(area.position.x + area.size.x * i / 6.0)
		var y := roundf(area.position.y + area.size.y * i / 6.0)
		draw_line(Vector2(x, area.position.y), Vector2(x, area.end.y), line, 1.0)
		draw_line(Vector2(area.position.x, y), Vector2(area.end.x, y), line, 1.0)


## Snaps a zone's color to the palette's sea blues (deep = dark).
func _sea_tone(color: Color) -> Color:
	var best: Color = sea_tones[0]
	for tone in sea_tones:
		if absf(tone.get_luminance() - color.get_luminance()) < absf(best.get_luminance() - color.get_luminance()):
			best = tone
	return best


func _font() -> Font:
	var bold := get_theme_font(&"font", &"BoldLabel")
	return bold if bold else get_theme_default_font()


## Dashed foam line: how far the current boat can go.
func _draw_range(font: Font) -> void:
	var range_y: float = _snap.get("range_y", -INF)
	if not is_finite(range_y):
		return
	var map_size: Vector2 = _snap["size"]
	var left := _to_map(Vector2(0, range_y))
	var right := _to_map(Vector2(map_size.x, range_y))
	draw_dashed_line(left, right, MapSymbols.BOAT, 1.0, 4.0)
	MapSymbols.label(self, font, left + Vector2(3, -3), "sóng lớn", label_size, Color("253a5e"))


func _draw_story_marks(font: Font, fog_open: bool) -> void:
	if fog_open:
		var at := _to_map(_snap["whirlpool"])
		MapSymbols.whirlpool(self, at)
		MapSymbols.label(self, font, at + Vector2(6, 3), "???", label_size, Color("253a5e"))
		return
	if Story.stage() >= 1:
		# Omen seen but fog not open: the GPS glitches over that corner.
		var corner := _to_map(Vector2(_snap["size"].x * 0.88, _snap["size"].y * 0.12))
		MapSymbols.label(self, font, corner - Vector2(20, 0),
			PhoneReports.glitch("[ERR] NaN", floori(Time.get_ticks_msec() / 400.0)), label_size, Color("a53030"))


# --- world <-> map coordinates (fit the whole map, centered) ---

func _scale() -> float:
	var map_size: Vector2 = _snap["size"]
	var usable := size - Vector2(12, 20)
	return minf(usable.x / map_size.x, usable.y / map_size.y)


func _origin() -> Vector2:
	var map_size: Vector2 = _snap["size"]
	return Vector2(roundf((size.x - map_size.x * _scale()) * 0.5), 6.0)


func _to_map(world_pos: Vector2) -> Vector2:
	return _origin() + world_pos * _scale()


func _to_map_rect(rect: Rect2) -> Rect2:
	return Rect2(_to_map(rect.position), rect.size * _scale())


func _to_world(map_pos: Vector2) -> Vector2:
	return (map_pos - _origin()) / _scale()
