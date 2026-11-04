class_name GhostCast3D
extends RefCounted
## The drowned cast (PLAN §10 "Dàn ma bằng model thật"): every ghost figure
## (fog figures, chasers, the pier head, the extra person, đêm âm, the faces)
## is a PSX pack body with GhostLook3D, taken in turn from POOL so two in a
## row never share a face. No collider, no shadow, pose frozen (dead still)
## through an UncannyActor3D. Loaded models stay cached after the first one.

## Order of appearance (deterministic): men, the long-haired ma da, the old
## man, women, the long-drowned body.
const POOL: Array[String] = ["drowned_m", "ma_da", "drowned_old", "drowned_f", "corpse", "ma_da_b"]
## The faces that fill the view (WrongNightScare3D variants 0, 1, 2).
const FACES: Array[String] = ["drowned_m", "ma_da", "drowned_f"]

static var _sequence := 0
static var _held: Dictionary = {}  # id -> PackedScene, kept loaded
static var _over_shader: Shader


## The next ghost id of the pool.
static func next_id() -> String:
	_sequence += 1
	return id_for(_sequence - 1)


static func id_for(seed: int) -> String:
	return POOL[posmod(seed, POOL.size())]


## A ghost under `parent` at its origin; `id` "" takes the next of the pool.
## `unique`: own body material (fade it with fade()).
static func figure(parent: Node3D, id: String = "", unique: bool = false) -> PersonRig3D:
	var pick := id if id != "" else next_id()
	_hold(pick)
	var rig := PersonRig3D.build(parent, pick)
	rig.name = "Ghost_" + pick
	UncannyMoves3D.ghost_body(rig)
	if unique:
		GhostLook3D.apply(rig.visual(), true)
	UncannyMoves3D.remove_shadow(rig)
	UncannyActor3D.attach(rig).freeze()
	return rig


## The rig's actor (stare / freeze / dash), if any.
static func actor_of(rig: Node3D) -> UncannyActor3D:
	return rig.get_node_or_null(UncannyActor3D.NODE_NAME) as UncannyActor3D if rig else null


## The ghost body materials under `rig` (for fading).
static func materials(rig: Node3D) -> Array[ShaderMaterial]:
	var out: Array[ShaderMaterial] = []
	for node in rig.find_children("*", "MeshInstance3D", true, false):
		var m := (node as MeshInstance3D).material_override as ShaderMaterial
		if GhostLook3D.is_ghost(m) and not out.has(m):
			out.append(m)
	return out


## Tweens the ghost's own material(s) to `to` opacity (needs `unique`).
static func fade(tween: Tween, rig: Node3D, to: float, seconds: float) -> void:
	for m in materials(rig):
		tween.tween_method(func(v: float) -> void: GhostLook3D.set_opacity(m, v), GhostLook3D.opacity(m), to, seconds)


## Drawn over everything, both faces (the reflection in the water).
static func draw_over(rig: Node3D) -> void:
	if _over_shader == null:
		_over_shader = Shader.new()
		_over_shader.code = GhostLook3D.SHADER.code.replace("render_mode cull_back,", "render_mode cull_disabled, depth_test_disabled,")
	for m in materials(rig):
		var copy := m.duplicate() as ShaderMaterial
		copy.shader = _over_shader
		copy.render_priority = 1
		for node in rig.find_children("*", "MeshInstance3D", true, false):
			if (node as MeshInstance3D).material_override == m:
				(node as MeshInstance3D).material_override = copy


static func _hold(id: String) -> void:
	if _held.has(id) or not PsxCharacterVisual.CAST.has(id):
		return
	_held[id] = load(PsxCharacterVisual.DIR + str(PsxCharacterVisual.CAST[id]) + ".fbx")
