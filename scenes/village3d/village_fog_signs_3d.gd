class_name VillageFogSigns3D
extends Node3D
## The small wrong things in the edge fog (WorldEdgeLoop3D), from the second
## try of the day: paper offerings (vàng mã) drifting back into the fog,
## against the way Rin walks; from the third, a still figure standing at the
## side of the path, gone when he comes close. Cleared when he leaves the fog.

@export var paper_count := 14
@export var paper_speed := 1.3
@export var figure_depth := 13.0
@export var figure_gone_within := 5.5

var _papers: Array[MeshInstance3D] = []
var _figure: Node3D
var _side := 0.0
var _clock := 0.0


## Shows tonight's sign on the path `side` (-1 west, +1 east) for try `count`.
func show_sign(count: int, side: float, loop: WorldEdgeLoop3D) -> void:
	_clear()
	_side = side
	var range_z := loop.east_z if side > 0.0 else loop.west_z
	var mouth := WorldEdgeLoop3D.EAST_MOUTH if side > 0.0 else WorldEdgeLoop3D.WEST_MOUTH
	if count >= 3:
		_figure = UncannyScene3D.silhouette(self, 1.7, 0.9)
		_figure.position = Vector3(mouth + side * figure_depth, 0, range_z.y - 0.6)
		_figure.rotation.y = side * PI * 0.5  # eyes (+Z) towards Rin coming out of the fog
		return
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color("c9a24a")
	gold.cull_mode = BaseMaterial3D.CULL_DISABLED
	var red := StandardMaterial3D.new()
	red.albedo_color = Color("8a2a24")
	red.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i in paper_count:
		var quad := QuadMesh.new()
		quad.size = Vector2(0.16, 0.1)
		var paper := MeshInstance3D.new()
		paper.mesh = quad
		paper.material_override = red if i % 4 == 0 else gold
		add_child(paper)
		var depth := 6.0 + float(i) * 1.1
		paper.position = Vector3(mouth + side * depth, 0.3 + float(i % 5) * 0.35, lerpf(range_z.x + 0.6, range_z.y - 0.6, float((i * 7) % 10) / 10.0))
		_papers.append(paper)


func update(player: Vector3, at: Vector2) -> void:
	if at.y == 0.0 or at.y != _side:
		if _side != 0.0 and at.y == 0.0:
			_clear()
		return
	var delta := get_process_delta_time()
	_clock += delta
	for i in _papers.size():
		var paper := _papers[i]
		# Into the fog, away from the village: the wind never blows that way here.
		paper.position.x += _side * paper_speed * delta * (0.7 + 0.1 * float(i % 4))
		paper.position.y = 0.3 + float(i % 5) * 0.35 + sin(_clock * 2.0 + float(i)) * 0.25
		paper.rotation = Vector3(_clock * 3.0 + float(i), _clock * 1.7, _clock * 2.3 + float(i))
		var mouth := WorldEdgeLoop3D.EAST_MOUTH if _side > 0.0 else WorldEdgeLoop3D.WEST_MOUTH
		if absf(paper.position.x - mouth) > 24.0:
			paper.position.x = mouth + _side * 5.0
	if _figure and player.distance_to(_figure.global_position) < figure_gone_within:
		_figure.queue_free()
		_figure = null


func has_sign() -> bool:
	return not _papers.is_empty() or _figure != null


func _clear() -> void:
	for paper in _papers:
		paper.queue_free()
	_papers.clear()
	if _figure:
		_figure.queue_free()
		_figure = null
	_side = 0.0
