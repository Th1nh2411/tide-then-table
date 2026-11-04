class_name RestaurantFurniture3D
extends RefCounted
## Street furniture meshes: the real models (assets/models/ready/<id>/<id>_reduced.glb
## via ConceptModel3D, VillageProps3D.kind() == "concept") fitted into the old
## footprints, else the old pilot / batch mesh. Visual only: colliders, FloorGrid3D,
## plate / seat / E positions stay with the callers.

const TABLE_PILOT = preload("res://assets/models/ready/table/table.glb")
## The old table.glb box (local, before TABLE_YAW): plates sit on its top.
const TABLE_SIZE := Vector3(1.5, 0.86, 1.2)
## Bảo's cart footprint (its collider / FloorGrid "kitchen counter"), centred on GRILL_POSITION.
const CART_SIZE := Vector3(2.8, 1.3, 1.25)
## Inside that footprint, west -> east: clay stove (by Bảo), glass cart, ice box (by the keg),
## local x from the centre.
const STOVE_AT := Vector3(-1.14, 0, -0.25)
const STOVE_SIZE := Vector3(0.5, 0.42, 0.5)
const GLASS_CART_AT := Vector3(-0.14, 0, 0)
const GLASS_CART_SIZE := Vector3(1.56, 1.95, 1.25)
const ICE_BOX_AT := Vector3(1.04, 0, 0.05)
const ICE_BOX_SIZE := Vector3(0.66, 0.5, 0.55)
## Spare stools stacked by the shop wall (prop only, never a guest seat).
const STOOL_STACK_SIZE := Vector3(0.5, 0.95, 0.45)


static func has_model(id: String) -> bool:
	return VillageProps3D.kind(id) == "concept"


## A dining table standing at `at`, turned `yaw`; the top is at TABLE_SIZE.y.
static func table(parent: Node3D, at: Vector3, yaw: float) -> Node3D:
	var root := Node3D.new()
	parent.add_child(root)
	root.position = at
	root.rotation.y = yaw
	if has_model("table_stall_folding"):
		# Squashed onto the old box so the oilcloth top is where plates sit.
		ConceptModel3D.sized(root, "table_stall_folding", Vector3.ZERO, TABLE_SIZE)
	else:
		root.add_child(TABLE_PILOT.instantiate())
		WorldPresentation3D.cast_shadows(root)
	return root


## Bảo's cart at `at` (GRILL_POSITION): clay stove + glass cart + ice box, or the old cart.
static func cart(parent: Node3D, at: Vector3) -> Node3D:
	if not has_model("food_cart_glass"):
		return RestaurantBatchVisuals.add(parent, "food_cart_0", at)
	var root := Node3D.new()
	root.name = "BaoCart"
	parent.add_child(root)
	root.position = at
	ConceptModel3D.fit(root, "food_cart_glass", GLASS_CART_AT, GLASS_CART_SIZE)
	if has_model("charcoal_stove_clay"):
		ConceptModel3D.fit(root, "charcoal_stove_clay", STOVE_AT, STOVE_SIZE)
		var coals := OmniLight3D.new()
		coals.name = "StoveCoals"
		root.add_child(coals)
		coals.position = STOVE_AT + Vector3(0, STOVE_SIZE.y + 0.1, 0)
		coals.light_color = Color("ff8a4a")
		coals.light_energy = 0.35
		coals.omni_range = 1.4
	if has_model("ice_box_styrofoam"):
		ConceptModel3D.fit(root, "ice_box_styrofoam", ICE_BOX_AT, ICE_BOX_SIZE)
	return root


## Spare plastic stools stacked at `at` (nothing when the model is missing).
static func stool_stack(parent: Node3D, at: Vector3, yaw: float = 0.0) -> Node3D:
	if not has_model("stool_plastic_stack"):
		return null
	return ConceptModel3D.fit(parent, "stool_plastic_stack", at, STOOL_STACK_SIZE, yaw)
