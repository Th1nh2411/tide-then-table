extends Node3D
## Bare gallery wrapper. Only stools are Hunyuan-derived; the table is the
## existing procedural visual while table inference is blocked by Space quota.

const ROOM = preload("res://scenes/restaurant3d/restaurant_room_builder_3d.gd")
const STOOL = preload("res://assets/models/pilots/stool/stool.glb")

func _ready() -> void:
	set_meta("table_status", "blocked_by_quota_existing_visual")
	set_meta("stool_status", "hunyuan_generated_600_triangles")
	var table := Node3D.new()
	table.name = "ExistingProceduralTable_PendingHunyuan"
	add_child(table)
	ROOM.box(table, Vector3(0, 0.8, 0), Vector3(1.5, 0.12, 1.2), "c7cfcc")
	for x: float in [-0.57, 0.57]:
		for z: float in [-0.4, 0.4]:
			ROOM.box(table, Vector3(x, 0.4, z), Vector3(0.07, 0.8, 0.07), "577277")
	for side: float in [-1.0, 1.0]:
		var stool: Node3D = STOOL.instantiate()
		stool.name = "HunyuanStoolBlue" if side < 0 else "HunyuanStoolRed"
		add_child(stool)
		stool.position = Vector3(side * 1.02, 0, 0)
		if side > 0:
			var red := ROOM.mat("a53030")
			for node: Node in stool.find_children("*", "MeshInstance3D", true, false):
				(node as MeshInstance3D).material_override = red
