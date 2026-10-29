extends Node3D
## Gallery wrapper for the finished Hunyuan table and stools.

const ROOM = preload("res://scenes/restaurant3d/restaurant_room_builder_3d.gd")
const STOOL = preload("res://assets/models/ready/stool/stool.glb")
const TABLE = preload("res://assets/models/ready/table/table.glb")

func _ready() -> void:
	set_meta("table_status", "hunyuan_generated_1200_triangles")
	set_meta("stool_status", "hunyuan_generated_600_triangles")
	var table: Node3D = TABLE.instantiate()
	table.name = "HunyuanTable"
	add_child(table)
	for side: float in [-1.0, 1.0]:
		var stool: Node3D = STOOL.instantiate()
		stool.name = "HunyuanStoolBlue" if side < 0 else "HunyuanStoolRed"
		add_child(stool)
		stool.position = Vector3(side * 1.02, 0, 0)
		if side > 0:
			var red := ROOM.mat("a53030")
			for node: Node in stool.find_children("*", "MeshInstance3D", true, false):
				(node as MeshInstance3D).material_override = red
