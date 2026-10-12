class_name PhoneMap
extends Control
## Map tab of the phone app. The sea scene captures its layout (zones, land,
## islands/rocks, dock, places) into a static snapshot, so the map also works
## from the restaurant, plus the current boat's range line. Live extras at
## sea: the boat (group "boat") and nets (group "net_buoys"). Click to add/remove a pin (GameState.map_pins);
## pins also show as edge markers at sea.

const PIN_HIT_RADIUS_PX: float = 8.0

@export var background: Color = Color(0.03, 0.05, 0.09)
@export var land_color: Color = Color(0.55, 0.5, 0.35)
@export var dock_color: Color = Color(1.0, 0.9, 0.4)
@export var place_color: Color = Color(1.0, 0.55, 0.4)
@export var boat_color: Color = Color(1.0, 1.0, 1.0)
@export var net_color: Color = Color(1.0, 0.55, 0.2)
@export var pin_color: Color = Color(1.0, 0.4, 0.9)
@export var fog_color: Color = Color(0.4, 1.0, 0.9)
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
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(Vector2.ZERO, size), background)
	if not has_snapshot():
		draw_string(font, Vector2(8, 20), "Chưa có dữ liệu bản đồ. Ra khơi một lần để đồng bộ.",
			HORIZONTAL_ALIGNMENT_LEFT, size.x - 16, 8, Color(0.7, 0.75, 0.8))
		return
	var fog_open := Story.is_fog_open()
	for zone: Dictionary in _snap["zones"]:
		if zone["fog"] and not fog_open:
			continue
		var color: Color = zone["color"]
		draw_rect(_to_map_rect(zone["rect"]), color.darkened(0.35))
		if show_legend and zone.has("name"):
			var r := _to_map_rect(zone["rect"])
			draw_string(font, r.position + Vector2(4, label_size + 3), zone["name"], HORIZONTAL_ALIGNMENT_LEFT, -1,
				label_size, Color(1, 1, 1, 0.45))
	for rect: Rect2 in _snap["land"]:
		draw_rect(_to_map_rect(rect), land_color)
	for rock: Dictionary in _snap["rocks"]:
		draw_circle(_to_map(rock["pos"]), maxf(float(rock["radius"]) * _scale(), 1.5), rock["color"])
	_draw_range(font)
	_draw_story_marks(font, fog_open)
	_draw_dot(font, _snap["dock"], "Bến", dock_color, 3.0)
	for place: Dictionary in _snap["places"]:
		_draw_dot(font, place["pos"], place["label"], place_color, 2.5)
	for buoy: Node2D in get_tree().get_nodes_in_group("net_buoys"):
		_draw_dot(font, buoy.global_position, "", net_color, 2.0)
	for i in GameState.map_pins.size():
		_draw_pin(font, GameState.map_pins[i], i + 1)
	_draw_boat()
	var hint := "Ghim %d/%d" % [GameState.map_pins.size(), GameState.MAX_PINS]
	var boat := get_tree().get_first_node_in_group("boat") as Node2D
	if boat:
		var meters := roundi(boat.global_position.distance_to(_snap["dock"]) / pixels_per_meter)
		hint += " · về bến %dm" % meters
	draw_string(font, Vector2(4, size.y - 4), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, Color(0.6, 0.65, 0.7))
	if show_legend:
		_draw_legend(font)


## Key to the symbols, bottom right.
func _draw_legend(font: Font) -> void:
	var items: Array = [["Thuyền", boat_color], ["Bến", dock_color], ["Địa điểm", place_color],
		["Lưới", net_color], ["Ghim", pin_color]]
	var x := size.x - 4.0
	for i in range(items.size() - 1, -1, -1):
		var text: String = items[i][0]
		x -= font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size).x
		draw_string(font, Vector2(x, size.y - 4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, Color(0.75, 0.8, 0.85))
		draw_circle(Vector2(x - 6, size.y - 4 - label_size * 0.35), 2.5, items[i][1])
		x -= 16.0


## Dashed foam line: how far the current boat can go.
func _draw_range(font: Font) -> void:
	var range_y: float = _snap.get("range_y", -INF)
	if not is_finite(range_y):
		return
	var map_size: Vector2 = _snap["size"]
	var left := _to_map(Vector2(0, range_y))
	var right := _to_map(Vector2(map_size.x, range_y))
	draw_dashed_line(left, right, Color(0.85, 0.95, 1.0, 0.8), 1.0, 4.0)
	draw_string(font, left + Vector2(2, -2), "sóng lớn", HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, Color(0.85, 0.95, 1.0))


func _draw_story_marks(font: Font, fog_open: bool) -> void:
	if fog_open:
		_draw_dot(font, _snap["whirlpool"], "???", fog_color, 3.0)
		return
	if Story.stage() >= 1:
		# Omen seen but fog not open: the GPS glitches over that corner.
		var corner := _to_map(Vector2(_snap["size"].x * 0.88, _snap["size"].y * 0.12))
		draw_string(font, corner - Vector2(20, 0), PhoneReports.glitch("[ERR] NaN", floori(Time.get_ticks_msec() / 400.0)),
			HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, Color(1.0, 0.35, 0.35))


func _draw_boat() -> void:
	var boat := get_tree().get_first_node_in_group("boat") as Node2D
	if boat == null:
		return
	var at := _to_map(boat.global_position)
	var pulse := fmod(Time.get_ticks_msec() * 0.001, 1.2) / 1.2  # "you are here" ring
	draw_arc(at, 4.0 + pulse * 10.0, 0.0, TAU, 20, Color(boat_color, 0.8 * (1.0 - pulse)), 1.0)
	var forward := Vector2.RIGHT.rotated(boat.global_rotation)
	var side := forward.orthogonal()
	draw_colored_polygon(PackedVector2Array([at + forward * 6.0, at - forward * 4.0 + side * 3.5,
		at - forward * 4.0 - side * 3.5]), boat_color)


func _draw_dot(font: Font, world_pos: Vector2, label: String, color: Color, radius: float) -> void:
	var at := _to_map(world_pos)
	draw_circle(at, radius, color)
	if label:
		draw_string_outline(font, at + Vector2(4, 3), label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, 2, Color.BLACK)
		draw_string(font, at + Vector2(4, 3), label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, color)


func _draw_pin(font: Font, world_pos: Vector2, number: int) -> void:
	var at := _to_map(world_pos)
	draw_line(at, at - Vector2(0, 7), pin_color, 1.5)
	draw_circle(at - Vector2(0, 8), 3.0, pin_color)
	draw_string(font, at + Vector2(-2, -12), str(number), HORIZONTAL_ALIGNMENT_LEFT, -1, label_size, pin_color)


# --- world <-> map coordinates (fit the whole map, centered) ---

func _scale() -> float:
	var map_size: Vector2 = _snap["size"]
	var usable := size - Vector2(8, 16)
	return minf(usable.x / map_size.x, usable.y / map_size.y)


func _origin() -> Vector2:
	var map_size: Vector2 = _snap["size"]
	return Vector2((size.x - map_size.x * _scale()) * 0.5, 4.0)


func _to_map(world_pos: Vector2) -> Vector2:
	return _origin() + world_pos * _scale()


func _to_map_rect(rect: Rect2) -> Rect2:
	return Rect2(_to_map(rect.position), rect.size * _scale())


func _to_world(map_pos: Vector2) -> Vector2:
	return (map_pos - _origin()) / _scale()
