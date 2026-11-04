class_name GateChain3D
extends RefCounted
## The chain on VillageGateAlley3D's gate: shut = wound twice round both
## leaves where they meet, a padlock hanging off it; open = the same chain
## hanging straight down the fixed leaf's edge, the padlock open in the dirt.

const LINK := Vector3(0.05, 0.028, 0.012)


## A node with the chain at `meet` (where the leaves meet, ground level).
static func build(parent: Node3D, meet: Vector3, open: bool) -> Node3D:
	var b := BoxBatch3D.new()
	var steel := BoxBatch3D.color("4a4640")
	var rust := BoxBatch3D.color("6a4430")
	var lock := BoxBatch3D.color("5c584e")
	if open:
		# Down the fixed (west) leaf's edge from the middle rail, a heap at the foot.
		for i in 16:
			var at := meet + Vector3(-0.05 + sin(float(i) * 0.9) * 0.012, 1.0 - float(i) * 0.055, 0.04)
			b.box(rust if i % 4 == 0 else steel, at, Vector3(LINK.y, LINK.x, LINK.z), float(i % 2) * PI * 0.5)
		for i in 7:
			b.box(steel, meet + Vector3(-0.12 + float(i) * 0.045, 0.02, 0.1 + float(i % 2) * 0.03), LINK, float(i) * 0.7)
		b.box(lock, meet + Vector3(0.18, 0.04, 0.22), Vector3(0.07, 0.08, 0.03), 0.0, PI * 0.5)
		b.box(steel, meet + Vector3(0.22, 0.04, 0.22), Vector3(0.012, 0.05, 0.05), 0.0, PI * 0.5)
	else:
		# Two loose turns round both edges, sagging, the lock under them.
		for turn in 2:
			for i in 12:
				var u := float(i) / 11.0
				var x := lerpf(-0.12, 0.12, u)
				var y := 1.04 - float(turn) * 0.09 - sin(u * PI) * 0.05
				var z := 0.05 if turn == 0 else -0.05
				b.box(rust if (i + turn) % 5 == 0 else steel, meet + Vector3(x, y, z), LINK, 0.0, float(i % 2) * PI * 0.5)
		b.box(lock, meet + Vector3(0.0, 0.86, 0.06), Vector3(0.07, 0.08, 0.03))
		b.box(steel, meet + Vector3(0.0, 0.92, 0.06), Vector3(0.05, 0.04, 0.012))
	return b.commit(parent, "Chain", false)
