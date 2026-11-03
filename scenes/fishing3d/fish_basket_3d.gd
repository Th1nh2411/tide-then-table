class_name FishBasket3D
extends Node3D
## The giỏ cá in the thúng: Rin drops each landed fish in with E while
## looking at it (Fishing3D). Shows the fish stacked inside and a small
## count. What it holds on docking is the night's catch (LoopCalendar).

## Where it sits in the boat (BoatVisual space): low, left of Rin.
const IN_BOAT := Vector3(-0.15, 0.2, -0.2)
const RADIUS := 0.27
const HEIGHT := 0.3

var fish: Array[FishData] = []
var sizes: Array[float] = []
var _stack := Node3D.new()
var _count := Label3D.new()


func _ready() -> void:
	ConceptModel3D.fit(self, "fish_basket", Vector3.ZERO, Vector3(RADIUS * 2.0, HEIGHT * 1.4, RADIUS * 2.0))
	add_child(_stack)
	_stack.position.y = HEIGHT + 0.01
	_count.font_size = 40
	_count.pixel_size = 0.004
	_count.outline_size = 10
	_count.modulate = Color("efe6d2")
	_count.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_count.position = Vector3(0, HEIGHT + 0.22, 0)
	add_child(_count)
	_refresh()


func count() -> int:
	return fish.size()


func add(caught: FishData, size: float) -> void:
	fish.append(caught)
	sizes.append(size)
	_refresh()


## Top of the basket in world space (Fishing3D's look check).
func mouth() -> Vector3:
	return global_position + global_basis.y * HEIGHT


func _refresh() -> void:
	for child in _stack.get_children():
		child.queue_free()
	for i in range(fish.size()):
		var model := fish_mesh(fish[i], sizes[i] * 0.55)
		_stack.add_child(model)
		var a := float(i) * 2.4
		model.position = Vector3(cos(a) * 0.08, float(i / 3) * 0.05, sin(a) * 0.08)
		model.rotation = Vector3(0, a + PI * 0.5, 0)
	_count.text = str(fish.size()) if not fish.is_empty() else ""


## Inferred species mesh shared by the hand, basket and restaurant display.
static func fish_mesh(caught: FishData, size: float) -> Node3D:
	var id := "fish_ca_thu"
	if caught:
		id = "fish_glowing" if caught.is_aberrant else "fish_" + caught.id
	if not ConceptModel3D.geometry(id):
		id = "fish_ca_thu"
	var holder := Node3D.new()
	var model := ConceptModel3D.aligned(holder, id, 0.32 * clampf(size, 0.3, 2.0), Vector3.RIGHT)
	if caught and caught.is_aberrant:
		for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
			(mesh.material_override as ShaderMaterial).set_shader_parameter("glow", 0.5)
	return holder
