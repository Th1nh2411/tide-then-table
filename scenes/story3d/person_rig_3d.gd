class_name PersonRig3D
extends Node3D
## Shared gameplay/cutscene actor API. Rin keeps his own rig; everyone else is
## a PSX pack model (`PsxCharacterVisual.CAST` maps variant ids to models).

## Supported story/gameplay actor IDs ("guest" / "drowned" pick one of a pool).
const LOOKS := {
	"rin": {}, "bao": {}, "co_nam": {}, "guest_rich": {}, "chu_hai": {},
	"ong_tam": {}, "ong_tu": {}, "chu_bay": {}, "vy": {}, "vy_sau": {}, "staff": {},
	"guest_1": {}, "guest_2": {}, "guest_3": {}, "guest_4": {}, "guest_5": {},
	"guest_6": {}, "guest_7": {}, "guest_8": {}, "guest_9": {},
	"guest_regular": {}, "drowned_m": {}, "drowned_f": {},
	"ma_da": {}, "ma_da_b": {}, "drowned_old": {}, "corpse": {},
	"guest": {}, "drowned": {},
}
const GUEST_POOL := 9

static var _guest_sequence: int = 0
static var _drowned_sequence: int = 0
var current_variant: String = ""
var _cat_visual: Node3D
var kind: String = ""
var legs: Array[Node3D] = []
var arms: Array[Node3D] = []
var plate: Node3D
var carrying := false
var _pilot: RinPilotVisual
var _walk_speed := 0.0
var _casting_clip := false
var _distance_driven := false
var _ground_frame := -1
var _ground_idle_frame := -1
var _blocker: CollisionShape3D
var _seated := false
var _once_left := 0.0


## Builds a rig of `kind` under `parent`; legacy shirt argument remains accepted.
static func build(parent: Node3D, kind_: String, shirt: String = "") -> PersonRig3D:
	var rig := PersonRig3D.new()
	rig.kind = kind_
	parent.add_child(rig)
	if kind_ == "cat":
		rig._build_cat()
		ContactShadow3D.attach(rig, 0.22, 1.4)
		return rig
	if kind_ == "rin":
		rig.current_variant = "rin"
		rig._build_rin_pilot()
	else:
		var variant := kind_
		if kind_ == "guest":
			variant = next_guest_variant()
		elif kind_ == "drowned":
			variant = "drowned_m" if _drowned_sequence % 2 == 0 else "drowned_f"
			_drowned_sequence += 1
		rig.current_variant = variant if variant in LOOKS else "guest_1"
		rig._build_rin_pilot()
	if kind_ != "guest" and kind_ != "drowned":
		rig.add_to_group("person_" + kind_)
	if kind_ != "rin":
		rig._add_blocker()
	# Grounds the person where no lamp casts a real shadow.
	ContactShadow3D.attach(rig, 0.36, 0.8)
	return rig


## Next look from the guest pool (odd ids are men, even ids women).
static func next_guest_variant() -> String:
	_guest_sequence += 1
	return "guest_%d" % (((_guest_sequence - 1) % GUEST_POOL) + 1)


## Walk cycle: `speed` 0..1 scales the swing, `clock` is the step time.
func set_walking(speed: float, clock: float) -> void:
	if _pilot:
		_distance_driven = false
		_walk_speed = speed
		_update_pilot_motion()
		return
	if kind == "cat":
		if _cat_visual:
			_cat_visual.position.y = absf(sin(clock * 9.0)) * 0.025 * speed
			_cat_visual.rotation.z = sin(clock * 9.0) * 0.025 * speed
		return
	var beat := floorf(clock * 8.0) / 8.0
	position.y = absf(sin(beat * 11.0)) * 0.04 * speed
	for i in range(legs.size()):
		var side := -1.0 if i == 0 else 1.0
		legs[i].rotation.x = side * sin(beat * 11.0) * 0.4 * speed
		arms[i].rotation.x = -side * sin(beat * 11.0) * 0.33 * speed
	if carrying:
		for arm in arms:
			arm.rotation.x = -0.8


## Displacement is in world coordinates; use the distance actually travelled after collision.
func drive_ground_motion(displacement: Vector3, delta: float, face_travel := true) -> void:
	if not _pilot or _casting_clip or _seated or delta <= 0.0: return
	_distance_driven = true
	_ground_frame = Engine.get_physics_frames()
	_ground_idle_frame = Engine.get_process_frames()
	var flat := Vector3(displacement.x,0,displacement.z)
	if face_travel and flat.length_squared() > 0.000001:
		var parent_space := get_parent_node_3d().global_basis.inverse()*flat
		rotation.y = lerp_angle(rotation.y,atan2(parent_space.x,parent_space.z),1.0-exp(-14.0*delta))
	_pilot.drive_ground_motion(flat.length()/maxf(global_basis.get_scale().x,.001),delta,carrying)
	_sync_pilot_anchors()

func set_seated(on: bool) -> void:
	if not _pilot: return
	if on and not SeatedAnimation3D.prepare(_pilot,RestaurantSeating3D.SEAT_HEIGHT): return
	_seated = on
	_distance_driven = false
	_walk_speed = 0.0
	if _pilot._foot_plant: _pilot._foot_plant.release()
	_pilot.set_motion("SitIdle" if on else "Idle")

func sample_seating(progress: float, standing_up := false) -> void:
	if not _pilot or not SeatedAnimation3D.prepare(_pilot,RestaurantSeating3D.SEAT_HEIGHT): return
	_seated = true
	_distance_driven = false
	if _pilot._foot_plant: _pilot._foot_plant.release()
	var clip := "StandUp" if standing_up else "SitDown"
	_pilot.sample_motion(clip,clampf(progress,0,1)*_pilot.animation.get_animation(clip).length)

func set_carrying(on: bool) -> void:
	carrying = on
	if _pilot:
		_update_pilot_motion()
	if plate:
		plate.visible = on
	if not on and not _pilot:
		for arm in arms:
			arm.rotation.x = 0.0


func _build_rin_pilot() -> void:
	if current_variant == "rin":
		_pilot = load("res://scenes/art_pilots/rin_pilot.tscn").instantiate() as RinPilotVisual
	else:
		var visual := PsxCharacterVisual.new()
		visual.asset_id = current_variant
		visual.name = "PsxPilot"
		_pilot = visual
	add_child(_pilot)
	# Preserve the old arms[] attachment contract. A casting rod still uses its
	# original local (0,-0.6,0) grip, but anchors now follow the actual skinned wrist.
	for side in [-1.0, 1.0]:
		var leg := Node3D.new()
		add_child(leg)
		leg.position = Vector3(side * 0.14, 0.91, -0.03)
		legs.append(leg)
		var arm := Node3D.new()
		add_child(arm)
		arm.position = Vector3(side * 0.31, 1.35, -0.025)
		arms.append(arm)
	plate = Node3D.new()
	add_child(plate)
	plate.position = Vector3(0, 1.0, 0.47)
	if current_variant != "rin" and _pilot and _pilot.skeleton:
		var hips := _pilot.skeleton.get_bone_global_rest(_pilot.skeleton.find_bone("Hips")).origin.y
		plate.position *= hips / 0.92
	plate.visible = false
	ServedFoodVisual3D.show_dish(plate, null)
	_sync_pilot_anchors()

func _update_pilot_motion() -> void:
	if _casting_clip or _distance_driven or _seated:
		return
	var moving := _walk_speed > 0.03
	var clip := ("CarryWalk" if moving else "Carry") if carrying else "Walk" if moving else "Idle"
	if not _pilot.animation.has_animation(clip):
		clip = "Carry" if carrying else "Idle"
	_pilot.set_motion(clip, clampf(_walk_speed, 0.35, 1.5) if moving else 1.0)

func _process(_delta: float) -> void:
	if not _pilot or not _pilot.skeleton:
		return
	if _once_left > 0.0:
		_once_left -= _delta
		if _once_left <= 0.0:
			_casting_clip = false
			_pilot.animation.speed_scale = 1.0
	if _casting_clip or _seated:
		_sync_pilot_anchors()
		return
	# Movers drive from physics (gameplay) or idle (cutscene tweens); idle only when neither did.
	if _distance_driven and Engine.get_physics_frames() > _ground_frame + 1 \
			and Engine.get_process_frames() > _ground_idle_frame + 1:
		_pilot.drive_ground_motion(0.0,_delta,carrying)
	var casting := false
	for i in range(arms.size()):
		if arms[i].get_child_count() > 0:
			casting = true
			_pilot.set_cast_arm(i, arms[i].rotation.x)
	if not casting:
		_pilot.clear_cast()
	_sync_pilot_anchors()

## Plays `clip` once over `seconds` (e.g. a dash roll), then walking takes over again.
func play_once(clip: String, seconds: float) -> void:
	if not _pilot or not _pilot.animation.has_animation(clip):
		return
	_casting_clip = true
	_once_left = seconds
	_pilot.animation.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE
	_pilot.animation.play(clip, 0.06)
	_pilot.animation.speed_scale = _pilot.animation.get_animation(clip).length / maxf(seconds, 0.05)

## Plays an authored one-shot clip (Faint...); walking / idle stop driving the pose.
## `at_end` jumps straight to its last pose (skipped cutscenes).
func play_clip(clip: String, at_end := false) -> void:
	if not _pilot or not _pilot.animation.has_animation(clip):
		return
	_casting_clip = true
	if at_end:
		_pilot.sample_motion(clip, _pilot.animation.get_animation(clip).length)
	else:
		_pilot.set_motion(clip)

## Sample the authored clip using the cinematic clock, including skip speed-up.
func sample_cast(seconds: float) -> void:
	_casting_clip = true
	_pilot.sample_motion("Cast", seconds)
	_sync_pilot_anchors()

func _sync_pilot_anchors() -> void:
	if not _pilot or not _pilot.skeleton:
		return
	if carrying:
		plate.position = (_pilot.hand_position("L") + _pilot.hand_position("R")) * 0.5 + Vector3(0, -0.04, 0.08)
	for i in range(arms.size()):
		if _casting_clip:
			arms[i].basis = _pilot.hand_basis("R" if i == 0 else "L")
		var wrist := _pilot.hand_position("R" if i == 0 else "L")
		arms[i].position = wrist - arms[i].basis * Vector3(0, -0.6, 0)


## Solid body so Rin (a CharacterBody3D) can't walk through other people;
## off while the person is hidden (empty seats, cutscene stand-ins).
func _add_blocker() -> void:
	if kind == "cat":
		return
	var body := StaticBody3D.new()
	body.name = "PersonBlocker"
	add_child(body)
	_blocker = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.24
	capsule.height = 1.6
	_blocker.shape = capsule
	_blocker.position.y = 0.8
	body.add_child(_blocker)
	visibility_changed.connect(_sync_blocker)
	_sync_blocker()

func _sync_blocker() -> void:
	if _blocker:
		_blocker.set_deferred("disabled", not is_visible_in_tree())

func _box(parent: Node3D, pos: Vector3, size: Vector3, hex: String) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	m.roughness = 0.85
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mesh.material_override = m
	parent.add_child(mesh)
	mesh.position = pos
	return mesh


## The body (skeleton + animation); null for the cat.
func visual() -> RinPilotVisual:
	return _pilot

func get_variant() -> String:
	return current_variant

func set_variant(id: String) -> void:
	if id == current_variant or not (id in LOOKS) or id in ["rin", "guest", "drowned"]:
		return
	if _pilot is PsxCharacterVisual:
		current_variant = id
		(_pilot as PsxCharacterVisual).load_variant(id)
		var hips := _pilot.skeleton.get_bone_global_rest(_pilot.skeleton.find_bone("Hips")).origin.y
		plate.position = Vector3(0, 1.0, 0.47) * hips / 0.92
		_update_pilot_motion()
		if _seated: set_seated(true)
		_sync_pilot_anchors()

func _build_cat() -> void:
	current_variant = "cat"
	_cat_visual = load("res://assets/models/ready/cat/cat.glb").instantiate()
	add_child(_cat_visual)
	WorldPresentation3D.cast_shadows(_cat_visual)
	add_to_group("person_cat")
