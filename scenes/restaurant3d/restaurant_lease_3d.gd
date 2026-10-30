class_name RestaurantLease3D
extends Node3D
## Opens real floor area only after the seats/lease upgrade has been purchased.
var room: Node3D
var _level := -1
var _tiles: Array[MeshInstance3D] = []
var _boundary: Node3D

static func build(host: Node3D) -> RestaurantLease3D:
	var lease := RestaurantLease3D.new()
	lease.name = "RestaurantLease"
	lease.room = host
	host.add_child(lease)
	return lease

func _ready() -> void:
	for tile in room.find_children("LeaseTile_*","MeshInstance3D",true,false): _tiles.append(tile)
	refresh()

func _process(_delta: float) -> void:
	if _level != GameState.get_upgrade_level("seats"): refresh()

func refresh() -> void:
	_level = GameState.get_upgrade_level("seats")
	var left := RestaurantLayout3D.lease_left(_level)
	for tile in _tiles:
		var at := tile.position
		tile.visible = at.z >= RestaurantLayout3D.PUBLIC_WALK_Z or (at.x>=left and at.x<=RestaurantLayout3D.LEASE_RIGHT)
	if is_instance_valid(_boundary):
		remove_child(_boundary)
		_boundary.queue_free()
	_boundary = Node3D.new()
	_boundary.name = "LeaseBoundary"
	add_child(_boundary)
	_fence(left)
	_fence(RestaurantLayout3D.LEASE_RIGHT)
	if _level < 2:
		var sign_ := Label3D.new()
		sign_.text = "GIAN BÊN CẠNH\nCHƯA THUÊ"
		sign_.font_size = 28
		sign_.pixel_size = .006
		sign_.modulate = Color("e7d5b3")
		sign_.outline_size = 2
		sign_.position = Vector3(left-1.4,.8,1.5)
		_boundary.add_child(sign_)

func _fence(x: float) -> void:
	var back := RestaurantLayout3D.BACK_Z
	var front := RestaurantLayout3D.PUBLIC_WALK_Z
	var mid := (back+front)*.5
	var collider := StaticBody3D.new()
	_boundary.add_child(collider)
	collider.position = Vector3(x,.8,mid)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(.14,1.6,front-back)
	shape.shape = box
	collider.add_child(shape)
	for i in range(ceili((front-back)/2)+1):
		_box(_boundary,Vector3(x,.4,minf(back+float(i)*2,front)),Vector3(.12,.8,.12),Color("795f46"))
	_box(_boundary,Vector3(x,.58,mid),Vector3(.08,.08,front-back),Color("795f46"))

static func preview(parent: Node3D, before: int, after: int) -> void:
	if after <= before: return
	var left := RestaurantLayout3D.lease_left(after)
	var right := RestaurantLayout3D.lease_left(before)
	var z := (RestaurantLayout3D.BACK_Z+RestaurantLayout3D.PUBLIC_WALK_Z)*.5
	_box(parent,Vector3((left+right)*.5,.025,z),Vector3(right-left,.025,RestaurantLayout3D.PUBLIC_WALK_Z-RestaurantLayout3D.BACK_Z),Color(.3,1,.45,.25))

static func _box(parent: Node3D, at: Vector3, size_: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size_
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = .9
	if color.a<1:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mesh.material_override = mat
	parent.add_child(mesh)
	mesh.position = at
