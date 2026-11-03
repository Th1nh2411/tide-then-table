class_name FallSafety3D
extends Node
## Safety net for the walkable 3D scenes (village map, night sea): if the
## player's body ever drops below `fall_y` (a hole in the ground, a bad
## teleport), the screen goes black for `black_seconds` and he is put back on
## the last point he stood safely. Attach once per scene with attach().

@export var fall_y := -5.0
## Heights counted as standing safely (the village has no gravity: y ~ 0).
@export var safe_band := Vector2(-1.0, 3.0)
@export var black_seconds := 0.5
@export var fade_seconds := 0.25

var target: Node3D
var last_safe := Vector3.ZERO
var rescues := 0
var _black := ColorRect.new()
var _left := 0.0


static func attach(owner: Node, body: Node3D) -> FallSafety3D:
	var node := FallSafety3D.new()
	node.name = "FallSafety"
	node.target = body
	owner.add_child(node)
	return node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	_black.color = Color.BLACK
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_black.set_anchors_preset(Control.PRESET_FULL_RECT)
	_black.modulate.a = 0.0
	layer.add_child(_black)
	if is_instance_valid(target):
		last_safe = target.global_position


func _physics_process(_delta: float) -> void:
	check()


## One check (tests call it directly). True when he was just put back.
func check() -> bool:
	if not is_instance_valid(target) or not target.is_inside_tree():
		return false
	var p := target.global_position
	if p.y < fall_y:
		_rescue()
		return true
	if p.y > safe_band.x and p.y < safe_band.y:
		last_safe = p
	return false


func _rescue() -> void:
	rescues += 1
	target.global_position = last_safe
	var body := target as CharacterBody3D
	if body:
		body.velocity = Vector3.ZERO
	_black.modulate.a = 1.0
	_left = black_seconds


func _process(delta: float) -> void:
	if _left > 0.0:
		_left -= delta
		return
	if _black.modulate.a > 0.0:
		_black.modulate.a = maxf(_black.modulate.a - delta / fade_seconds, 0.0)
