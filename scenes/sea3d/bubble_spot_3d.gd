class_name BubbleSpot3D
extends Node3D
## The only sign of a fish shoal at sea: bubbles rising and popping on the
## water. More fish left = more bubbles. Only drawn near the boat, inside the
## lamp's reach (`view_range`, set by the sea scene from the lamp).

const MIN_BUBBLES: int = 3
const BUBBLES_PER_FISH: int = 2
const MAX_BUBBLES: int = 16
const SPREAD: float = 1.6
const LIFE: float = 1.4

var shoal: SeaShoals3D.Shoal
var viewer: Node3D
var view_range: float = 8.0
var bubbles: Array[MeshInstance3D] = []
var _phases: Array[float] = []
var _offsets: Array[Vector2] = []
var _clock: float = 0.0
## True while the bubbles can be seen (shoal alive and boat inside range).
var shown: bool = false


static func bubble_count_for(fish_left: int) -> int:
	return clampi(MIN_BUBBLES + fish_left * BUBBLES_PER_FISH, 0, MAX_BUBBLES) if fish_left > 0 else 0


func setup(shoal_: SeaShoals3D.Shoal, viewer_: Node3D, mat: Material) -> void:
	shoal = shoal_
	viewer = viewer_
	position = shoal.pos
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(shoal.pos)
	for i in range(MAX_BUBBLES):
		var node := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.09
		mesh.height = 0.18
		mesh.radial_segments = 6
		mesh.rings = 3
		node.mesh = mesh
		node.material_override = mat
		node.visible = false
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
		bubbles.append(node)
		_phases.append(rng.randf())
		_offsets.append(Vector2(rng.randf_range(-SPREAD, SPREAD), rng.randf_range(-SPREAD, SPREAD)))


func _process(delta: float) -> void:
	_clock += delta
	update_bubbles()


## Separate from _process so tests can step it by hand.
func update_bubbles() -> void:
	var alive: bool = shoal != null and shoal.fish_left > 0
	shown = alive and is_instance_valid(viewer) and viewer.position.distance_to(position) <= view_range
	var count: int = bubble_count_for(shoal.fish_left) if alive else 0
	for i in range(bubbles.size()):
		var node: MeshInstance3D = bubbles[i]
		if not shown or i >= count:
			node.visible = false
			continue
		var t: float = fposmod(_clock / LIFE + _phases[i], 1.0)
		node.visible = true
		# Rise a little, then swell and pop at the surface.
		node.position = Vector3(_offsets[i].x, 0.08 + t * 0.35, _offsets[i].y)
		var s: float = 0.6 + t * 0.5 if t < 0.85 else 1.6 - (t - 0.85) * 10.0
		node.scale = Vector3.ONE * maxf(s, 0.05)
