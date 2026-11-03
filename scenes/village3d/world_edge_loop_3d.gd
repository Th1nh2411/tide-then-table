class_name WorldEdgeLoop3D
extends Node3D
## Exit-8 style edges of the village map (no text): the pavement west of the
## street and the shore path east of the waterfront both walk into fog that
## thickens until it is a wall; LOOP_DEPTH metres in, Rin is moved into the
## other path at the mirrored depth, still walking the same way (both run
## along -X / +X), so the village simply comes back out of the fog from the
## other side. Tries are counted per day (not saved): from the second one a
## small wrong thing waits in the fog (VillageFogSigns3D).

## [mouth x, direction (+1 east, -1 west), z range] of the two fog paths.
const WEST_MOUTH := -20.0
const EAST_MOUTH := 81.0
@export var loop_depth := 25.0
@export var haze_from := 4.0
@export var haze_full := 22.0
@export var veil_from := 13.0
@export var veil_max := 0.97
## Depths of the fog sheets hung across each path.
@export var sheet_depths: Array[float] = [9.0, 14.0, 18.0, 22.0, 26.0, 30.0]
@export var sheet_alpha := 0.42

static var _day := -1
static var _tries := 0

var host: VillageScene3D
var west_z := StreetFacades3D.WEST_Z
var east_z := VillageEdges3D.EAST_Z
var _veil := ColorRect.new()
var _sheets: Array[MeshInstance3D] = []
var _sheet_material := StandardMaterial3D.new()
var _signs: VillageFogSigns3D


static func attach(owner: VillageScene3D) -> WorldEdgeLoop3D:
	var node := WorldEdgeLoop3D.new()
	node.name = "WorldEdgeLoop"
	node.host = owner
	owner.add_child(node)
	return node


## Tries today (a new day starts at zero).
static func tries() -> int:
	return _tries if _day == GameState.day else 0


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_veil.modulate.a = 0.0
	layer.add_child(_veil)
	_sheet_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_sheet_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_sheet_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_sheet_material.disable_fog = true
	_sheet_material.albedo_texture = _soft_texture()
	for depth in sheet_depths:
		_sheet(WEST_MOUTH - depth, Vector2(-30.0, 46.0))
		_sheet(EAST_MOUTH + depth, Vector2(-34.0, 42.0))
	_signs = VillageFogSigns3D.new()
	add_child(_signs)


## Soft fog: thick at the bottom middle, fading to nothing at the top and sides.
func _soft_texture() -> ImageTexture:
	var image := Image.create(64, 32, false, Image.FORMAT_RGBA8)
	for y in 32:
		for x in 64:
			var u := absf(float(x) / 63.0 * 2.0 - 1.0)
			var v := float(y) / 31.0
			var a := (1.0 - u * u * u) * smoothstep(0.05, 0.75, v) * sheet_alpha
			image.set_pixel(x, y, Color(1, 1, 1, a))
	return ImageTexture.create_from_image(image)


## A fog sheet across a path at `x`, spanning z (range), facing along X.
func _sheet(x: float, z: Vector2) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(z.y - z.x, 20.0)
	var mesh := MeshInstance3D.new()
	mesh.mesh = quad
	mesh.material_override = _sheet_material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mesh)
	mesh.position = Vector3(x, 8.0, (z.x + z.y) * 0.5)
	mesh.rotation.y = PI * 0.5
	_sheets.append(mesh)


## How deep (m) `p` is in a fog path: Vector2(depth, side) with side -1 west,
## +1 east, 0 when on neither path.
func depth_at(p: Vector3) -> Vector2:
	if p.x < WEST_MOUTH and p.z > west_z.x - 0.5 and p.z < west_z.y + 0.5:
		return Vector2(WEST_MOUTH - p.x, -1.0)
	if p.x > EAST_MOUTH and p.z > east_z.x - 0.5 and p.z < east_z.y + 0.5:
		return Vector2(p.x - EAST_MOUTH, 1.0)
	return Vector2.ZERO


## Where `p` comes out on the other path (same heading, mirrored depth).
func looped(p: Vector3) -> Vector3:
	var at := depth_at(p)
	var depth := 2.0 * loop_depth - at.x
	if at.y < 0.0:
		return Vector3(EAST_MOUTH + depth, p.y, p.z - west_z.x + east_z.x)
	return Vector3(WEST_MOUTH - depth, p.y, p.z - east_z.x + west_z.x)


func _process(_delta: float) -> void:
	if host == null or host.player == null or host.lighting == null:
		return
	var tint := _fog_color()
	_sheet_material.albedo_color = Color(tint, 1.0)
	_veil.color = tint
	var p := host.player.global_position
	var at := depth_at(p)
	if at.y != 0.0 and at.x >= loop_depth:
		_loop(p)
		p = host.player.global_position
		at = depth_at(p)
	host.lighting.set_haze(smoothstep(haze_from, haze_full, at.x) if at.y != 0.0 else 0.0)
	_veil.modulate.a = smoothstep(veil_from, loop_depth, at.x) * veil_max if at.y != 0.0 else 0.0
	_signs.update(p, at)


func _loop(p: Vector3) -> void:
	host.player.global_position = looped(p)
	if _day != GameState.day:
		_day = GameState.day
		_tries = 0
	_tries += 1
	var at := depth_at(host.player.global_position)
	if _tries >= 2:
		_signs.show_sign(_tries, at.y, self)


func _fog_color() -> Color:
	match host.lighting.phase:
		VillageLighting3D.Phase.MORNING:
			return Color("98a2aa")
		VillageLighting3D.Phase.SHIFT:
			return Color("7d6e70")
	return Color("161d2e")
