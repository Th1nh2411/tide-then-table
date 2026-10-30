class_name ContactShadow3D
extends RefCounted
## Soft round "blob" shadow under people, furniture and boats, so they sit on
## the ground even where no lamp casts a real shadow. A Decal projecting down,
## child of the thing it grounds (moves with it). Forward+ only; elsewhere it
## is simply not added.

## Darkness at the centre (0..1).
const STRENGTH: float = 0.45
## How far above / below the node origin the decal reaches (floor + feet).
const REACH: float = 0.35

static var _texture: GradientTexture2D


static func supported() -> bool:
	return RenderingServer.get_current_rendering_method() == "forward_plus"


## Adds a blob of `radius` metres (x) by `radius * depth_ratio` (z) under `node`.
static func attach(node: Node3D, radius: float, depth_ratio: float = 1.0, strength: float = STRENGTH) -> Decal:
	if not supported() or node == null:
		return null
	var decal := Decal.new()
	decal.name = "ContactShadow"
	decal.texture_albedo = _blob()
	decal.size = Vector3(radius * 2.0, REACH * 2.0, radius * 2.0 * depth_ratio)
	decal.modulate = Color(0, 0, 0, strength)
	# Albedo only: it darkens, it doesn't change normals or roughness.
	decal.normal_fade = 0.5
	decal.upper_fade = 0.2
	decal.lower_fade = 0.2
	node.add_child(decal)
	decal.position = Vector3(0, 0.05, 0)
	return decal


static func _blob() -> GradientTexture2D:
	if _texture:
		return _texture
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	gradient.add_point(0.55, Color(1, 1, 1, 0.6))
	_texture = GradientTexture2D.new()
	_texture.gradient = gradient
	_texture.fill = GradientTexture2D.FILL_RADIAL
	_texture.fill_from = Vector2(0.5, 0.5)
	_texture.fill_to = Vector2(1.0, 0.5)
	_texture.width = 64
	_texture.height = 64
	return _texture
