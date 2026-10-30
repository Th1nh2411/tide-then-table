class_name RestaurantCamera3D
extends Camera3D
## Close gameplay framing with a dead zone, soft tracking and bounded room coverage.
const VIEW_SIZE := 12.0
const OFFSET := Vector3(3.3,10.5,13.5)
var target: Node3D
var _focus := Vector3(0,0,-.5)
var _destination := Vector3(0,0,-.5)

func _ready() -> void:
	projection = Camera3D.PROJECTION_ORTHOGONAL
	size = VIEW_SIZE
	_apply()

func _process(delta: float) -> void:
	if not current or not is_instance_valid(target): return
	track(target.global_position,delta)

func track(at: Vector3, delta: float) -> void:
	# A small dead zone keeps the room steady during serving and short adjustments.
	if absf(at.x-_destination.x)>2.0: _destination.x = at.x-signf(at.x-_destination.x)*2.0
	if absf(at.z-_destination.z)>1.25: _destination.z = at.z-signf(at.z-_destination.z)*1.25
	_destination.x = clampf(_destination.x,-11.5,11.5)
	_destination.z = clampf(_destination.z,-4.0,3.0)
	_focus = _focus.lerp(_destination,1.0-exp(-5.0*maxf(delta,0)))
	_apply()

func _apply() -> void:
	global_position = _focus+OFFSET
	look_at(_focus+Vector3.UP*.55)
